# ![WooCommerce BreachBox logo](./assets/img/woobreachboxlogo.png)

WooCommerce BreachBox is the web's only intentionaly vulnerable WooCommerce application. Based on WordPress, this WooCommerce installation includes vulnerabilities in both the WordPress and WooCommerce engines. Included in the setup is a vulnerable hosting environment which makes it possible to hack from the application layer all the way to the server.

![WooCommerce WPScan](./assets/video/woowpscan.gif)

⚠️ **DO NOT DEPLOY THIS IN A PRODUCTION ENVIRONMENT**

## Software Versions
  - **WordPress** 5.0
  - **WooCommerce** 3.4.0
  - **Contact-Form-7** 5.0.3
  - **WP-Statistics** 12.6.6

## Setup
The software environment is dependent on two virtual machines `db_server` and `web_server`. Always provision `db_server` first.
```
vagrant up db_server web_server
```

## Contributing
Clone the repository and create a pull request if you have any contributions you believe should be added to the repository. Some additions that we need:
  - Containerized infrastructure
  - Clear UI workflow:
      - my-account link
      - cart link
      - contact-us link
  
