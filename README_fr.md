# Glitch-Soc pour YunoHost

[![Niveau d'intégration](https://dash.yunohost.org/integration/glitchsoc.svg)](https://dash.yunohost.org/appci/app/glitchsoc) ![](https://ci-apps.yunohost.org/ci/badges/glitchsoc.status.svg) ![](https://ci-apps.yunohost.org/ci/badges/glitchsoc.maintain.svg)  
[![Installer Glitch-Soc avec YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=glitchsoc)

*[Read this readme in english.](./README.md)*
*[Lire ce readme en français.](./README_fr.md)*

> *Ce package vous permet d'installer Glitch-Soc rapidement et simplement sur un serveur YunoHost.
Si vous n'avez pas YunoHost, regardez [ici](https://yunohost.org/#/install) pour savoir comment l'installer et en profiter.*

## Vue d'ensemble

`glitch-soc` est une [scission](https://fr.wikipedia.org/wiki/Fork_(d%C3%A9veloppement_logiciel)) sympa du logiciel de réseau social libre [Mastodon](https://joinmastodon.org/), avec comme objectif de fournir des fonctionnalités supplémentaires, au risque d'un logiciel un peu moins stable.

###  Quelles sont les différences avec Mastodon?

`glitch-soc` ajoute de nombreuses fonctionnalitées expérimentals, comme :

- Améliorations des média
  - Images masquées pas le CW
  - Images en pleine largeure
  - Options de mise à l'échelle
- Formattage des pouets
- Sélectionner les réponses dans les listes
- Amélioration des filtres
- Mise en avant des liens trompeurs
- Cacher les compteur d'abonné⋅e⋅s
- Une boite de paramètres
- Pouets pliants
- Icones pour le niveau de visibilité des pouets
- Pouets locaux
- Mode fil de pouts
- Attribut `data-*` sur les pouets
- Gestion des thèmes avancée via flavours+skins
- Doodle

Voir plus [sur la documentation](https://glitch-soc.github.io/docs/) (en anglais).


**Version incluse :** 2022.04.28~ynh1



## Avertissements / informations importantes

Glitch-Soc est en constant développement, fournis avec les dernières fonctionnalités (incluant les derniers bugs).

### Installation

* L'application a besoin d'un domaine dédié.
* L'utilisateurice choisie lors de l'installation sera administrateurice de l'instance. Il est possible d'en ajouter d'autre depuis l'application.

L'authentification par LDAP et le Single-Sign-On sont activés pour les utilisateurices YunoHost.

Nous vous invitons à bloquer les instances malveillantes depuis l'interface d'administration. Vous pouvez également ajouter du texte sur votre page d'accueil.

### Problèmes connus

* En se connectant via le SSO, se déconnecter depuis le portail YunoHost ne vous déconnecte pas de Glitch-Soc. Voir https://github.com/YunoHost/issues/issues/501

## Documentations et ressources

* Site officiel de l'app : https://glitch-soc.github.io/docs/
* Dépôt de code officiel de l'app : https://github.com/glitch-soc/mastodon
* Documentation YunoHost pour cette app : https://yunohost.org/app_glitchsoc
* Signaler un bug : https://github.com/YunoHost-Apps/glitchsoc_ynh/issues

## Informations pour les développeurs

Merci de faire vos pull request sur la [branche testing](https://github.com/YunoHost-Apps/glitchsoc_ynh/tree/testing).

Pour essayer la branche testing, procédez comme suit.
```
sudo yunohost app install https://github.com/YunoHost-Apps/glitchsoc_ynh/tree/testing --debug
ou
sudo yunohost app upgrade glitchsoc -u https://github.com/YunoHost-Apps/glitchsoc_ynh/tree/testing --debug
```

**Plus d'infos sur le packaging d'applications :** https://yunohost.org/packaging_apps