# Neno SmartLife App

Neno SmartLife App is a Flutter-based mobile commerce platform built for **Neno SmartLife General Electronics**, an electronics retailer located in Bafoussam, Cameroon.

The platform allows customers to browse products, save favorites, submit purchase requests, and communicate directly with the store owner, while providing administrators with tools to manage products, customer requests, orders, and sales history.

Unlike a traditional e-commerce platform, payments and delivery are handled manually between the customer and the business, keeping the experience simple and closely aligned with the business's current workflow.

---

## Features

### Customer Features

- Browse products without creating an account.
- Search and filter products by category.
- View detailed product information and specifications.
- Save favorite products.
- Add products to cart.
- Submit purchase requests.
- Chat directly with the business owner.
- Track pending and completed orders.
- View purchase history.

### Admin Features

- Add, edit, and delete products.
- Manage categories.
- Define custom product specifications.
- View customer requests.
- Confirm, ship, complete, or cancel orders.
- Chat with customers.
- View customer purchase history.
- Track completed sales.

---

## Product Categories

Examples include:

- Phones
- Phone Accessories
- Televisions
- Smart Watches
- Bluetooth Speakers
- Headphones
- Tablets
- Laptops
- Gaming Devices
- Other Electronics

---

## Authentication

Customers are not required to create traditional accounts.

When a customer wants to:

- Save a favorite
- Add products to cart
- Submit a request

they simply provide:

- Full name
- Phone number

The phone number serves as the customer's unique identifier.

---

## Order Flow

1. Customer browses products.
2. Customer adds products to cart.
3. Customer submits a purchase request.
4. Admin reviews and confirms the request.
5. Customer and admin communicate through chat.
6. Payment and delivery happen offline.
7. Admin marks the order as completed.
8. The order moves to the customer's purchase history.

---

## Tech Stack

- Flutter
- Dart
- Firebase / Supabase (TBD)
- Clean Architecture
- BLoC State Management
- REST APIs

---

## Project Structure

```text
lib/
├── core/
├── features/
├── shared/
├── services/
├── routes/
└── main.dart
```

---

## Design Principles

- Simple and intuitive.
- Minimal number of screens.
- WhatsApp-inspired browsing experience.
- Fast product discovery.
- Manual checkout workflow.
- Mobile-first experience.
- Clean and modern UI.

---

## Future Improvements

- Online payments.
- Push notifications.
- Product stock tracking.
- Customer reviews and ratings.
- Delivery tracking.
- Promotional banners.
- Discount codes.
- Multi-admin support.

---

## Status

🚧 Currently under active development.

---

## License

This project is proprietary and developed specifically for Neno SmartLife General Electronics. All rights reserved.
