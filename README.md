

---

<!--
N.B.: This README was automatically generated by https://github.com/YunoHost/apps/tree/master/tools/README-generator
It shall NOT be edited by hand.
-->

# Glich-Soc for YunoHost

[![Integration level](https://dash.yunohost.org/integration/glitchsoc.svg)](https://dash.yunohost.org/appci/app/glitchsoc) ![](https://ci-apps.yunohost.org/ci/badges/glitchsoc.status.svg)  ![](https://ci-apps.yunohost.org/ci/badges/glitchsoc.maintain.svg)
[![Install glitchsoc with YunoHost](https://install-app.yunohost.org/install-with-yunohost.svg)](https://install-app.yunohost.org/?app=glitchsoc)

*[Lire ce readme en français.](./README_fr.md)*

> *This package allows you to install glitchsoc quickly and simply on a YunoHost server.
If you don't have YunoHost, please consult [the guide](https://yunohost.org/#/install) to learn how to install it.*

## Overview

A libre and federated social network, fork of Mastodon.

**Shipped version:** 3.4.0-rc2~ynh1






## Disclaimers / important information

Glitch-Soc is beta software, and under active development. Use at your own risk!

* This app require a dedicated domain or subdomain.
* The user choosen during the installation is created in Glich-Soc with admin rights. At the end of the installation a mail is sent to the user with the a generated password.
* LDAP authentication is activated. All YunoHost users can authenticate.
* It seems important to close the inscriptions for your Glitch-Soc, so that it remains a private body. We invite you to block remote malicious instances from the administration interface. You can also add text on your home page.



## Documentation and resources

* Official app website: https://glitch-soc.github.io/docs/


* Upstream app code repository:  https://github.com/glitch-soc/mastodon
* YunoHost documentation for this app: https://yunohost.org/app_glitchsoc
* Report a bug: https://github.com/YunoHost-Apps/glitchsoc_ynh/issues

## Developer info

Please send your pull request to the [testing branch](https://github.com/YunoHost-Apps/glitchsoc_ynh/tree/testing).

To try the testing branch, please proceed like that.
```
sudo yunohost app install https://github.com/YunoHost-Apps/glitchsoc_ynh/tree/testing --debug
or
sudo yunohost app upgrade glitchsoc -u https://github.com/YunoHost-Apps/glitchsoc_ynh/tree/testing --debug
```

**More info regarding app packaging:** https://yunohost.org/packaging_apps