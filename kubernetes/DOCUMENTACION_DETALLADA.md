# Documentación Técnica: Despliegue de Aplicación de Microservicios con Kubernetes

## Introducción

Este documento profundiza en las decisiones técnicas, la arquitectura y el proceso de depuración seguido para el despliegue de la aplicación de votación de microservicios. El objetivo es detallar el razonamiento detrás de las configuraciones de Kubernetes y demostrar una comprensión práctica de los principios de orquestación de contenedores en un entorno distribuido.

---

### 1. Filosofía de Diseño: Desacoplamiento y Orquestación

La decisión de usar Kubernetes para este proyecto se basa en su capacidad para gestionar aplicaciones complejas de forma declarativa. La arquitectura de la aplicación se dividió en componentes lógicos (microservicios), cada uno con una única responsabilidad, siguiendo los principios de diseño de software moderno.

* **Componentes sin Estado (Stateless):** `vote-app`, `result-app` y `worker` fueron diseñados como servicios sin estado. Esto significa que no almacenan datos de sesión persistentes, lo que permite a Kubernetes escalarlos, reiniciarlos o moverlos entre nodos sin pérdida de información, garantizando una alta disponibilidad.
* **Componentes con Estado (Stateful):** `postgres` y `redis` son, por naturaleza, servicios con estado. Aunque para este proyecto se utilizaron `Deployments` por simplicidad, en un entorno de producción real, se emplearía un `StatefulSet` para gestionar su identidad de red estable y su almacenamiento persistente de forma más robusta.

---

### 2. Análisis de Decisiones Técnicas por Componente

Cada componente fue encapsulado en su propio conjunto de manifiestos de Kubernetes para promover la modularidad y la gestión independiente.

#### **PostgreSQL (`db`)**
* **Configuración Explícita:** El `Deployment` de PostgreSQL se configuró explícitamente con todas las variables de entorno necesarias (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`). Esta decisión evita depender de los valores por defecto de la imagen de Docker, lo que garantiza un **proceso de inicialización determinista y predecible**. Se eliminó la ambigüedad para asegurar que las credenciales de creación fueran idénticas a las de conexión.
* **Gestión de Credenciales:** El usuario y la contraseña se extrajeron a un objeto `Secret`, asegurando que ninguna información sensible estuviera codificada en el manifiesto del `Deployment`.
* **Versión de la Imagen:** Se fijó la imagen en `postgres:16` para garantizar la reproducibilidad del entorno y evitar fallos inesperados causados por actualizaciones automáticas de la etiqueta `:latest`.

#### **Redis**
* **Rol en la Arquitectura:** Redis se utilizó como una cola de mensajes y caché en memoria, actuando como un intermediario de alta velocidad entre la aplicación de votación y el `worker`. Esto **desacopla el frontend del backend**, permitiendo que la aplicación de votación responda instantáneamente sin esperar a la escritura en la base de datos persistente.
* **Autenticación:** La imagen estándar de Redis se desplegó sin autenticación, una práctica común para componentes internos dentro de una red de clúster segura y de confianza.

#### **Worker (El Procesador en Segundo Plano)**
* **Ausencia de `Service`:** **Esta es una decisión de diseño deliberada.** El `worker` no tiene un `Service` asociado porque es un componente puramente **cliente**. No expone ningún puerto ni espera conexiones entrantes. Su función es iniciar conexiones hacia Redis (para leer votos) y hacia PostgreSQL (para escribirlos). Crear un `Service` para él sería innecesario y conceptualmente incorrecto, ya que no hay nada que "descubrir".
* **Dependencia de Componentes Externos:** El `worker` depende críticamente de la disponibilidad de Redis y PostgreSQL. Su código incluye una lógica de reintento (`Waiting for db`), lo que demuestra un patrón de resiliencia.

---

### 3. Estrategia de Red y Comunicación

La red del clúster se diseñó para ser segura y eficiente, siguiendo el principio de mínimo privilegio.

* **`ClusterIP` para Servicios Internos:** Tanto `postgres` (renombrado a `db`) como `redis` se expusieron con un `Service` de tipo `ClusterIP`. Esto les asigna una dirección IP interna estable accesible solo desde dentro del clúster, **impidiendo cualquier acceso directo desde el exterior** y protegiendo las bases de datos.
* **`NodePort` para Interfaces de Usuario:** Los frontends (`vote-app` y `result-app`) se expusieron con `NodePort` para facilitar el acceso y las pruebas durante el desarrollo en Minikube. Se entiende que en un entorno de producción, esto sería reemplazado por un objeto **`Ingress`**, que proporciona enrutamiento HTTP/S avanzado, terminación TLS y gestión de dominios.
* **Descubrimiento de Servicios por DNS:** Las aplicaciones se configuraron para encontrar las bases de datos utilizando los nombres de los `Services` (`db`, `redis`), aprovechando el DNS interno de Kubernetes (CoreDNS). Esto elimina la necesidad de codificar IPs, haciendo que la aplicación sea portátil entre diferentes clústeres.

---

### 4. Proceso de Depuración Sistemática

El despliegue de este proyecto presentó múltiples desafíos del mundo real que requirieron un enfoque de depuración metódico. Este proceso fue más valioso que el propio despliegue:

1.  **Diagnóstico de `CrashLoopBackOff`:** El `worker` fallaba repetidamente. Utilizando `kubectl logs --previous`, se obtuvo el *stack trace* de la aplicación, que reveló un error de DNS.
2.  **Aislamiento del Problema de DNS:** Se descubrió que la aplicación `worker` tenía un nombre de host (`db`) codificado en su interior, que no coincidía con el nombre del `Service` (`postgres-service`). Esto forzó una decisión consciente: **adaptar la infraestructura a los requisitos de una aplicación "caja negra"**, una tarea común en la integración de sistemas.
3.  **Resolución de Errores de Autenticación:** A pesar de corregir el DNS, la conexión seguía fallando. El siguiente paso fue **espiar los logs del servidor de PostgreSQL en tiempo real** (`kubectl logs -f`) mientras se forzaba el reinicio de un cliente. Esto reveló el error real: `FATAL: password authentication failed`.
4.  **Prueba de Conexión Manual:** Para aislar definitivamente el problema, se lanzó un pod de depuración temporal (`kubectl run`) y se utilizó el cliente `psql` para conectar manualmente a la base de datos. La prueba tuvo éxito, demostrando que la base de datos, el `Service` y el `Secret` eran correctos, y que el problema residía en cómo los **clientes de la aplicación** gestionaban la autenticación.
5.  **Diagnóstico Final:** La investigación concluyó que las imágenes de las aplicaciones cliente tenían **credenciales de usuario y contraseña codificadas**, ignorando las variables de entorno inyectadas. La solución final fue adaptar el `Secret` y la inicialización de la base de datos para que coincidieran con estas credenciales codificadas.

Este ciclo de depuración demuestra una comprensión profunda de las herramientas de diagnóstico de Kubernetes y la capacidad de resolver problemas complejos en un sistema distribuido.

---

### 5. Exposición Segura de Servicios con Ingress y TLS

Para llevar el despliegue a un nivel más cercano a la producción, se reemplazó el acceso inicial mediante `Services` de tipo `NodePort` por una solución de enrutamiento de capa 7 centralizada y segura.

#### **Decisión: `Ingress` vs. `NodePort`/`LoadBalancer`**

* **Centralización:** En lugar de exponer un puerto en cada nodo por cada servicio de frontend, se instaló un **Ingress Controller de NGINX**. Este actúa como un único punto de entrada (`Single Point of Entry`) para todo el tráfico HTTP/S, simplificando la gestión de la red y las reglas de firewall.
* **Enrutamiento Inteligente:** Se creó un único recurso `Ingress` para gestionar el tráfico a los dos frontends. Utilizando el **enrutamiento basado en host**, las peticiones a `vote.local` se dirigen al servicio de votación, mientras que las de `result.local` se dirigen al de resultados. Esto se logra mediante la inspección del `Host header` de la petición HTTP, una funcionalidad de capa 7.
* **Aislamiento de Servicios:** Al usar `Ingress`, los `Services` de las aplicaciones (`vote-app-service`, `result-service`) pudieron ser cambiados a `ClusterIP`, su tipo por defecto. Esto significa que ya no son accesibles directamente desde la red del nodo, y todo el tráfico debe pasar obligatoriamente por las reglas definidas en el `Ingress`, aumentando la seguridad.

#### **Implementación de TLS (HTTPS)**

Para asegurar la confidencialidad e integridad de los datos en tránsito, se habilitó la encriptación TLS.

* **Generación de Certificados:** Se utilizó la herramienta `openssl` para generar un **certificado autofirmado (self-signed)**. Se empleó un único certificado válido para ambos dominios (`vote.local` y `result.local`) mediante el uso de la extensión **Subject Alternative Name (SAN)**, que es la práctica moderna estándar para certificados multidominio.
* **Almacenamiento Seguro:** El par de clave-certificado se almacenó en el clúster utilizando un `Secret` de Kubernetes de tipo `kubernetes.io/tls`. Este mecanismo desacopla la gestión de los certificados de la configuración del `Ingress`.
* **Configuración del Ingress:** La sección `spec.tls` del recurso `Ingress` se configuró para hacer referencia al `Secret` creado. Esto le instruye al `Ingress Controller` que termine las conexiones TLS (realice el "saludo" TLS) para los hosts especificados usando el certificado y la clave proporcionados, asegurando que el tráfico entre el cliente y el clúster esté encriptado.

---

### 6. Securización de la Red Interna con Network Policies

Para implementar una estrategia de **Defensa en Profundidad** y adoptar un modelo de **Confianza Cero (Zero Trust)**, se implementó una capa de seguridad de red interna utilizando `Network Policies`. El objetivo era asegurar que, incluso si un componente fuera comprometido, su capacidad para moverse lateralmente dentro del clúster (`lateral movement`) estaría severamente restringida.

#### **Decisión: Habilitar un CNI con Soporte para Políticas**

Por defecto, el driver de red de Minikube no fuerza el cumplimiento de las `Network Policies`. Para habilitar esta funcionalidad, el clúster se inició explícitamente con el **CNI (Container Network Interface) de Calico**. Esta decisión es fundamental, ya que Calico actúa como el "motor" que interpreta y aplica las reglas de firewall definidas en los manifiestos de `NetworkPolicy`.

#### **Estrategia de Implementación**

La implementación siguió un enfoque de "denegar todo por defecto, permitir explícitamente":

1.  **Política Base `default-deny-all`:** Se aplicó una política inicial que selecciona todos los pods (`podSelector: {}`) del `namespace` y bloquea todo el tráfico de `Ingress` y `Egress`. Esto estableció una línea base de aislamiento total, forzando la definición explícita de cada flujo de comunicación necesario.

2.  **Apertura de Flujos de Comunicación Legítimos:** Se crearon políticas granulares para cada flujo de comunicación requerido por la aplicación:
    * **Acceso Externo:** Se creó una política `Ingress` para permitir la entrada a los pods de `vote-app` y `result-app`, pero **únicamente desde los pods del `namespace` `ingress-nginx`**. Esto asegura que ningún otro pod del clúster pueda acceder directamente a los frontends.
    * **Comunicación con Bases de Datos:** Se definieron políticas de `Ingress` para `redis` y `postgres` que solo aceptan conexiones desde los pods autorizados (`vote-app`, `worker`, `result-app`).
    * **Control de Tráfico Saliente (`Egress`):** Se crearon políticas de `Egress` para cada componente de la aplicación (`vote-app`, `worker`, `result-app`). Estas reglas limitan sus conexiones salientes **únicamente a los servicios que necesitan consumir**. Por ejemplo, la política del `vote-app` solo le permite hablar con `redis`, bloqueando cualquier intento de conexión a la base de datos `postgres` o a cualquier otro pod. Esta medida es crucial para contener el "radio de explosión" en caso de que un pod sea comprometido.
    * **Permiso de DNS:** Todas las políticas de `Egress` incluyen una regla explícita que permite el tráfico saliente por el puerto `53/UDP`. Esto es un detalle crítico, ya que sin acceso al DNS interno del clúster (CoreDNS), los pods no podrían resolver los nombres de los `Services` y toda la comunicación fallaría.

Esta configuración de microsegmentación demuestra una comprensión avanzada de la seguridad en redes nativas de la nube, transformando una aplicación funcional en una arquitectura resiliente y segura.

---

### 7. Monitorización y Observabilidad con Prometheus y Grafana

Para completar el ciclo de vida de la aplicación, se implementó una pila de monitorización estándar en la industria para proporcionar observabilidad sobre el estado y el rendimiento del clúster y sus componentes.

#### **Decisión: `kube-prometheus-stack` con Helm**

En lugar de construir una solución de monitorización desde cero, se optó por desplegar el chart de Helm `kube-prometheus-stack`. Esta decisión se basa en las siguientes ventajas:
* **Estándar de la Industria:** Es la colección de herramientas de monitorización para Kubernetes más utilizada y mantenida por la comunidad.
* **Integración Completa:** Empaqueta no solo Prometheus y Grafana, sino también `Alertmanager` para la gestión de alertas y los `exporters` necesarios (`node-exporter`, `kube-state-metrics`) que se despliegan y configuran automáticamente.
* **Gestión Simplificada:** El uso de Helm permite instalar, actualizar y gestionar todo el ecosistema de monitorización como una única unidad coherente.

#### **Personalización para Minikube**

Durante la implementación, se detectó que los dashboards de Grafana no mostraban las métricas de consumo de recursos en tiempo real. La depuración reveló que Prometheus no podía "scrapear" los endpoints `/metrics/cadvisor` de los `kubelets` debido a una política de verificación de TLS en Minikube.

La solución fue personalizar el chart de Helm mediante un fichero `values.yaml` para desactivar esta verificación (`insecureSkipVerify: true`), una práctica común y segura en entornos de desarrollo. Este paso demuestra la habilidad de **adaptar una herramienta estándar a las particularidades de un entorno específico**, una tarea diaria en roles de DevOps.

#### **Acceso a Grafana**

Para el acceso a la interfaz de Grafana, que se despliega como un `Service` de tipo `ClusterIP` en su propio `namespace` `monitoring`, se utilizó el comando `kubectl port-forward`. Esta técnica establece un túnel seguro y temporal para el acceso administrativo, sin necesidad de exponer el servicio de forma permanente e insegura con un `NodePort` o `LoadBalancer`.