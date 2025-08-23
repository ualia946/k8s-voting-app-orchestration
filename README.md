# Despliegue End-to-End de Microservicios en Azure con Terraform, Kubernetes y CI/CD

Este proyecto demuestra un flujo de trabajo DevOps completo y automatizado para desplegar una aplicación de microservicios segura, escalable y observable en un entorno de nube profesional. La solución abarca desde la definición de la infraestructura como código (IaC) en Azure con Terraform, hasta la orquestación de contenedores con Kubernetes (AKS) y la automatización del despliegue continuo con GitHub Actions.

---

## 🏛️ Arquitectura Global y Flujo CI/CD

Este diagrama ilustra el ciclo de vida completo del proyecto: desde que un desarrollador empuja código a GitHub hasta que la aplicación está desplegada y monitorizada en Azure Kubernetes Service.

---

## ✨ Logros Clave y Habilidades Demostradas

* **Automaticé** el despliegue completo de una aplicación de microservicios en Azure, **reduciendo el tiempo de puesta en producción de horas a minutos** y eliminando errores manuales, mediante la creación de un pipeline CI/CD con GitHub Actions que aprovisiona la infraestructura con Terraform y despliega los manifiestos en AKS.
* **Aprovisioné** una infraestructura cloud segura y escalable en Azure, **garantizando un 100% de reproducibilidad y consistencia**, mediante la definición declarativa de todos los recursos (AKS, VNet, ACR, NSGs) como código con Terraform, gestionando el estado de forma remota para facilitar la colaboración.
* **Implementé** un modelo de seguridad de red de Confianza Cero (Zero Trust), **reduciendo drásticamente la superficie de ataque**, mediante la escritura de Network Policies granulares en Kubernetes que controlan el tráfico de Ingress y Egress para cada microservicio.
* **Orquesté** una aplicación distribuida de 5 microservicios, **asegurando la alta disponibilidad, escalabilidad y auto-reparación** de cada componente, mediante la escritura de manifiestos declarativos para Deployments, Services y Secrets de Kubernetes.
* **Establecí** una pila de monitorización y observabilidad completa, **obteniendo visibilidad en tiempo real del estado y consumo de recursos del clúster**, mediante el despliegue de Prometheus y Grafana con Helm, permitiendo la detección proactiva de anomalías.
* **Optimicé** el ciclo de vida del software, **garantizando la portabilidad y consistencia entre entornos**, mediante la containerización de 5 microservicios con Docker y la gestión centralizada de artefactos en Azure Container Registry (ACR).
* **Diseñé y depuré** sistemáticamente arquitecturas de red complejas en la nube, **resolviendo problemas de conectividad, DNS y permisos (IAM)**, mediante el análisis de logs y el uso de herramientas de diagnóstico de Azure y kubectl.

---

## 🚀 Pilares del Proyecto

### 1. Infraestructura como Código (IaC) con Terraform

La totalidad de la infraestructura de Azure se define de forma declarativa, permitiendo crear, modificar y versionar el entorno de forma segura y eficiente.

* **Recursos Gestionados:** Azure Kubernetes Service (AKS), Virtual Network (VNet), Subredes, Azure Container Registry (ACR), Network Security Groups (NSG).
* **Estado Remoto:** El estado de Terraform se almacena en un backend de Azure, permitiendo el trabajo en equipo y la consistencia.

### 2. Orquestación Segura con Kubernetes (AKS)

La aplicación de microservicios se despliega en AKS, aprovechando las capacidades nativas de Kubernetes para la gestión, seguridad y escalabilidad.

* **Gestión de Tráfico:** NGINX Ingress Controller para enrutar el tráfico externo de forma centralizada.
* **Seguridad:** TLS para comunicación HTTPS y Network Policies (Calico) para segmentación de red interna.
* **Configuración:** ConfigMaps y Secrets para desacoplar la configuración y las credenciales de las imágenes de contenedor.

### 3. Automatización CI/CD con GitHub Actions

Un pipeline automatizado se encarga de todo el proceso de despliegue, desde la construcción de la imagen hasta la actualización de la aplicación en producción.

* **Disparador:** Se activa automáticamente con cada `git push` a la rama `main`.
* **Pasos Clave:**
    1.  Construcción y etiquetado de la imagen Docker.
    2.  Publicación de la imagen en Azure Container Registry (ACR).
    3.  Aprovisionamiento o actualización de la infraestructura con Terraform.
    4.  Despliegue de los manifiestos de Kubernetes en el clúster de AKS.

---

## 🛠️ Tecnologías Utilizadas

| Categoría                 | Tecnologías                                       |
| ------------------------- | ------------------------------------------------- |
| **Cloud Provider** | Microsoft Azure                                   |
| **Infraestructura como Código** | Terraform                                         |
| **CI/CD** | GitHub Actions                                    |
| **Orquestación** | Kubernetes (Azure Kubernetes Service - AKS)       |
| **Contenerización** | Docker                                            |
| **Redes y Seguridad** | NGINX Ingress, Calico, Network Policies, TLS/SSL  |
| **Monitorización** | Prometheus, Grafana, Helm                         |
| **Bases de Datos** | PostgreSQL, Redis                                 |

---

## 📁 Estructura del Repositorio

```bash
.
├── .github/workflows/    
│   └── deploy.yml
├── kubernetes/            
│   ├── vote-app/
│   ├── result-app/
│   ├── worker/
│   └── README_KUBERNETES.md           
├── terraform/              
│   ├── main.tf
│   ├── aks.tf
│   └── README_TERRAFORM.md           
└── README.md               
