# Despliegue de Aplicación de Microservicios Segura con Kubernetes con MINIKUBE en local.

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white) ![NGINX](https://img.shields.io/badge/NGINX%20Ingress-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white) ![Calico](https://img.shields.io/badge/Calico-%23FF6A00.svg?style=for-the-badge&logo=c&logoColor=white) ![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white) ![Postgres](https://img.shields.io/badge/postgres-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white) ![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white) ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white) ![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)

Esta carpeta contiene un conjunto de archivos de Kubernetes para desplegar una aplicación de votación distribuida, segura y observable. El proyecto demuestra la orquestación de contenedores, la gestión de tráfico con **Ingress**, la securización con TLS/Network Policies para conseguir una política  **Zero Trust**, y la **monitorización** completa de una arquitectura de microservicios.

**➡️ [Ver la Documentación Técnica Detallada](DOCUMENTACION_DETALLADA.md)**

---

### 🚀 Arquitectura y Flujo de Tráfico

La aplicación se compone de 5 servicios contenerizados. El tráfico externo es gestionado por un **Ingress Controller de NGINX**, mientras que la comunicación interna está estrictamente controlada por **Network Policies**. Todo el ecosistema es monitorizado en tiempo real por **Prometheus** y visualizado con **Grafana**.

![Diagrama de Arquitectura de Microservicios con Ingress](images/arquitectura-k8s.png)

---

### 🖼️ Aplicación en Funcionamiento

Una vez desplegada, la aplicación expone dos interfaces web seguras (HTTPS), cada una en su propio dominio local.

#### **Interfaz de Votación (`https://vote.local`)**
![Interfaz de la Aplicación de Votación](images/https-connection-success.png)

#### **Interfaz de Resultados (`https://result.local`)**
![Interfaz de la Aplicación de Resultados](images/result-app-ui.png)

#### **Panel de Monitorización (Grafana)**
Un dashboard de Grafana que muestra el estado y consumo de recursos del clúster y los pods en tiempo real.
![Dashboard de Grafana monitorizando el clúster](images/grafana-dashboard.png)

---

### 💡 Logros y Habilidades Demostradas

* **Implementé una pila de monitorización completa**, obteniendo visibilidad en tiempo real del estado y consumo de recursos del clúster, mediante el despliegue de **Prometheus** para la recolección de métricas y **Grafana** para la visualización de dashboards con un chart de **Helm**.

* **Implementé un modelo de seguridad de red de Confianza Cero (Zero Trust)**, reduciendo drásticamente la superficie de ataque interna, mediante la escritura de **Network Policies** específicas que controlan el tráfico de `Ingress` y `Egress` para cada microservicio.

* **Orquesté una aplicación completa de 5 microservicios**, garantizando la alta disponibilidad y el auto-reparado de cada componente, mediante la escritura de manifiestos declarativos para **Deployments** de Kubernetes.

* **Implementé un punto de entrada único y seguro para todo el clúster**, centralizando la gestión del tráfico y habilitando la comunicación encriptada (HTTPS), mediante la configuración de un **Ingress Controller** y la gestión de certificados **TLS** almacenados en `Secrets`.

* **Diseñé un sistema de comunicación de red robusto**, asegurando que las bases de datos permanecieran aisladas de la exposición pública, mediante el uso estratégico de `Services` de tipo **`ClusterIP`** y el enrutamiento de capa 7 del **Ingress**.

* **Centralicé y gestioné la configuración de la aplicación de forma segura**, permitiendo despliegues portátiles y eliminando credenciales del código fuente, mediante la inyección de datos desde objetos **`ConfigMap`** y **`Secret`** como variables de entorno.

* **Diagnostiqué y resolví un complejo problema de fallo en cascada**, superando errores de autenticación, DNS e incompatibilidades entre componentes, mediante el análisis sistemático de logs de aplicación y de servidor, y la inspección en vivo de los objetos del clúster con **`kubectl`**.

---

### 🛠️ Tecnologías Utilizadas

* **Orquestación**: Kubernetes (Minikube)
* **Redes**: Ingress-NGINX, Calico (CNI)
* **Seguridad**: Network Policies, TLS/SSL (OpenSSL)
* **Contenerización**: Docker
* **Bases de Datos**: PostgreSQL, Redis
* **Despliegue**: `kubectl`

---

### ⚙️ Cómo Desplegar

**Prerrequisitos:**
* Tener [**Minikube**](https://minikube.sigs.k8s.io/docs/start/) instalado.
* Tener [**kubectl**](https://kubernetes.io/docs/tasks/tools/) instalado y configurado.

**Pasos:**
1.  **Inicia Minikube con el CNI de Calico.**
    ```bash
    minikube start --network-plugin=cni --cni=calico
    ```

2.  Clona este repositorio:
    ```bash
    git clone https://github.com/ualia946/k8s-voting-app-orchestration
    cd k8s-voting-app-orchestration
    ```

3.  **Habilita el addon de Ingress** y **despliega la pila de monitorización** con Helm:
    ```bash
    # Habilitar Ingress
    minikube addons enable ingress
    
    # Desplegar Prometheus y Grafana
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace -f values.yaml
    ```

4.  **Aplica todos los manifiestos** de la aplicación:
    ```bash
    kubectl apply -f . -R
    ```

5.  **Configura tu DNS local** con la IP de Minikube en tu fichero `/etc/hosts`.

6.  **Accede a las aplicaciones** en tu navegador:
    * `https://vote.local`
    * `https://result.local`

    *(Nota: Acepta la advertencia de seguridad del certificado autofirmado).*
