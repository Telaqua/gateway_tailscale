# Description

Ce script facilite l'installation de Tailscale sur différentes versions des gateways RAK: RAK7249, RAK7289C et RAK7289CV2.

Les binaires fournis dans ce repository sont des versions réduites de Tailscale, dans lesquelles les symboles de débogage ont été supprimés et les fonctions de "tailscale" et "tailscaled" ont été mutualisées en un seul binaire. De plus, le binaire est compressé.

Les architectures des gateways RAK7249, RAK7289C et RAK7289CV2 sont légèrement différentes. Il est nécessaire d'activer la compilation "softfloat" pour la version RAK7289CV2 mais pas pour les autres. Pour cette raison, deux binaires sont disponibles dans le repository. Les paquets contiennent simplement les scripts de configuration et `init.d` pour permettre la gestion de Tailscale en tant que service. Ils ont été créés à partir des paquets dédiés à OpenWRT mais modifiés pour supprimer les binaires originaux. Le paquet utilisé est disponible à l'adresse suivante : [tailscale_1.58.2-1_mipsel_24kc.ipk](https://downloads.openwrt.org/releases/23.05.2/packages/mipsel_24kc/packages/tailscale_1.58.2-1_mipsel_24kc.ipk).

Le gestionnaire de paquets "opkg" des firmwares de version 1.x.x utilise des paquets pour les architectures "ramips", tandis que les versions 2.x.x utilisent les paquets "mipsel". C'est pour cette raison que deux paquets différents sont présents dans le repository.

Le script identifie les modèles et les versions de gateways afin de sélectionner et télécharger le binaire et le paquet adaptés.

# Exécution du script

La première étape consiste à créer une "Auth Keys" sur l'interface d'administration de Tailscale. Cette clé sera passée au script pour lui permettre d'identifier la gateway sur le réseau Tailscale.

Ensuite, télécharger le script sur la gateway et l'exécuter en lui passant la clé comme variable d'environnement "TAILSCALE_TOKEN":

```bash
gateway$ wget https://raw.githubusercontent.com/Telaqua/gateway_tailscale/main/tailscale_install.sh
gateway$ chmod +x tailscale_install.sh
gateway$ env TAILSCALE_TOKEN=<tailscale_key> ./tailscale_install.sh
```

Remplacer <tailscale_key> par la clé Tailscale.
