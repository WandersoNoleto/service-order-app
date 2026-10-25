# service-order-app
Offline-first Android app to create service orders and export them as A4 PDF or image, ready to share on WhatsApp or print. Built with Flutter.

## Development

Each client is a build flavor. Branding (company name, logo, colors) comes from
`clients/<folder>/config.json` and `clients/<folder>/branding/logo.png`.

| Flavor     | Config folder           | Application ID                               |
|------------|-------------------------|----------------------------------------------|
| `standard` | `clients/default/`      | `com.wandersonnoleto.service_order_app`      |
| `val`      | `clients/private/val/`  | `com.wandersonnoleto.service_order_app.val`  |

`clients/private/` is a separate private repository and is not part of this one.

Run the demo build:

```bash
flutter run --flavor standard --dart-define-from-file=clients/default/config.json
```
