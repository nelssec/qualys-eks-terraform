# Qualys platform URLs

`qualys_platform` selects both chart URLs. Find your platform from the URL you log in to (Help > About in the Qualys UI also shows it).

| `qualys_platform` | Login URL host | `global.gatewayUrl` | `global.cmsqagPublicUrl` |
| --- | --- | --- | --- |
| US1 | qualysguard.qualys.com | https://gateway.qg1.apps.qualys.com | https://cmsqagpublic.qg1.apps.qualys.com/ContainerSensor |
| US2 | qualysguard.qg2.apps.qualys.com | https://gateway.qg2.apps.qualys.com | https://cmsqagpublic.qg2.apps.qualys.com/ContainerSensor |
| US3 | qualysguard.qg3.apps.qualys.com | https://gateway.qg3.apps.qualys.com | https://cmsqagpublic.qg3.apps.qualys.com/ContainerSensor |
| US4 | qualysguard.qg4.apps.qualys.com | https://gateway.qg4.apps.qualys.com | https://cmsqagpublic.qg4.apps.qualys.com/ContainerSensor |
| GOV1 | qualysguard.gov1.qualys.us | https://gateway.gov1.qualys.us | https://cmsqagpublic.gov1.qualys.us/ContainerSensor |
| EU1 | qualysguard.qualys.eu | https://gateway.qg1.apps.qualys.eu | https://cmsqagpublic.qg1.apps.qualys.eu/ContainerSensor |
| EU2 | qualysguard.qg2.apps.qualys.eu | https://gateway.qg2.apps.qualys.eu | https://cmsqagpublic.qg2.apps.qualys.eu/ContainerSensor |
| EU3 | qualysguard.qg3.apps.qualys.it | https://gateway.qg3.apps.qualys.it | https://cmsqagpublic.qg3.apps.qualys.it/ContainerSensor |
| IN1 | qualysguard.qg1.apps.qualys.in | https://gateway.qg1.apps.qualys.in | https://cmsqagpublic.qg1.apps.qualys.in/ContainerSensor |
| CA1 | qualysguard.qg1.apps.qualys.ca | https://gateway.qg1.apps.qualys.ca | https://cmsqagpublic.qg1.apps.qualys.ca/ContainerSensor |
| AE1 | qualysguard.qg1.apps.qualys.ae | https://gateway.qg1.apps.qualys.ae | https://cmsqagpublic.qg1.apps.qualys.ae/ContainerSensor |
| UK1 | qualysguard.qg1.apps.qualys.co.uk | https://gateway.qg1.apps.qualys.co.uk | https://cmsqagpublic.qg1.apps.qualys.co.uk/ContainerSensor |
| AU1 | qualysguard.qg1.apps.qualys.com.au | https://gateway.qg1.apps.qualys.com.au | https://cmsqagpublic.qg1.apps.qualys.com.au/ContainerSensor |
| KSA1 | qualysguard.qg1.apps.qualysksa.com | https://gateway.qg1.apps.qualysksa.com | https://cmsqagpublic.qg1.apps.qualysksa.com/ContainerSensor |

Private platforms: leave `qualys_platform` at any value and set `gateway_url` and `cmsqag_public_url` explicitly; the explicit values win.

Both hostnames must be reachable from the worker nodes on TCP 443 (directly or via `proxy`).
