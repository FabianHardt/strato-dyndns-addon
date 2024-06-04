# Home Assistant Add-on: StratoDynDNS

This is a fork of the official [repo](https://github.com/home-assistant/addons/tree/master/duckdns). The purpose is to add support for Strato DynDNS service.

Automatically update your Strato DynDNS IP address with integrated HTTPS support via Let's Encrypt.

![Supports aarch64 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armhf Architecture][armhf-shield] ![Supports armv7 Architecture][armv7-shield]

## Installation

Follow these steps to get the add-on installed on your system:

1. Click here:

   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FFabianHardt%2Fstrato-dyndns-addon)

1. Scroll down the page to find the new repository, and click in the new add-on named **_Strato DynDNS_**.
1. Click in the **_INSTALL_** button.

## About

[Strato DynDNS](https://www.strato-hosting.co.uk/faq/hosting/this-is-how-easy-it-is-to-set-up-dyndns-for-your-domains/) is a service that points a DNS (domains or sub-domains of your hosted domains) to an IP of your choice. This add-on includes support for Let’s Encrypt and automatically creates and renews your certificates. You need to Strato customer, with active domains, before using this add-on.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armhf-shield]: https://img.shields.io/badge/armhf-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg
[Strato DynDNS]: https://www.strato-hosting.co.uk/faq/hosting/this-is-how-easy-it-is-to-set-up-dyndns-for-your-domains/
