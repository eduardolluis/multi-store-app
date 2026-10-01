<div align="center">

# Multi Store

**Multi-vendor e-commerce application built with Flutter**

A mobile commerce project with separate customer and supplier experiences, product discovery, cart and checkout flows, order management, store management, payments, and cloud-backed services.

![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?style=flat-square&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Services-FFCA28?style=flat-square&logo=firebase&logoColor=111827)
![Supabase](https://img.shields.io/badge/Supabase-Integration-3ECF8E?style=flat-square&logo=supabase&logoColor=white)
![Stripe](https://img.shields.io/badge/Stripe-Payments-635BFF?style=flat-square&logo=stripe&logoColor=white)

</div>

---

## About

Multi Store is a Flutter e-commerce application designed around two main roles: **customers** and **suppliers**.

Customers can discover products and stores, browse categories, view product details, manage a cart and wishlist, place orders, and review their purchases. Suppliers have tools for managing products, store information, orders, and business activity from their own dashboard flow.

## Features

### Customer experience

- Customer authentication and account flows
- Product and store discovery
- Category-based browsing
- Product detail views
- Shopping cart management
- Wishlist support
- Checkout and order placement
- Customer order history
- Payment flows

### Supplier experience

- Supplier authentication
- Product creation and editing
- Product image management
- Store and business information management
- Product management dashboard
- Supplier order management
- Order status flows
- Balance and business views

### Platform capabilities

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging
- Local notifications
- Google Sign-In
- Stripe integration
- PayPal integration
- Provider state management
- Local persistence with SharedPreferences and SQLite
- Supabase integration

## Tech Stack

| Area | Technologies |
|---|---|
| Framework | Flutter, Dart |
| State management | Provider |
| Authentication | Firebase Auth, Google Sign-In |
| Database & cloud | Cloud Firestore, Firebase Storage, Supabase |
| Payments | Stripe, PayPal |
| Notifications | Firebase Messaging, Flutter Local Notifications |
| Local persistence | SharedPreferences, SQLite |
| Media | Image Picker |

## Project Structure

```text
lib/
├── address_book/          # Customer address flows
├── auth/                  # Customer and supplier authentication
├── categories/            # Product category views
├── customer_screens/      # Orders and wishlist
├── dashboard_components/  # Supplier management tools
├── gallery/               # Product media/gallery features
├── main_screens/          # Home, cart, category and dashboards
├── minor_screens/         # Product detail, checkout and editing flows
├── models/                # Cart, order, product and wishlist models
└── main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.11.3`
- A configured Firebase project
- Required service credentials/environment values for the integrations you plan to use

### Run locally

```bash
git clone https://github.com/eduardolluis/multi-store-app.git
cd multi-store-app
flutter pub get
flutter run
```

Before running cloud-backed features, configure the Firebase and environment settings required by the project.

---

## Author

**Eduardo De La Cruz**  
Full-Stack Software Developer · Web & Mobile

- [Portfolio](https://portfolio-one-blue-anckqnppbh.vercel.app/)
- [GitHub](https://github.com/eduardolluis)
- [LinkedIn](https://www.linkedin.com/in/eduardo-de-la-cruz-b6171837a/)
