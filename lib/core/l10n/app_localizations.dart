// Lightweight hand-rolled i18n — no code-gen dependency required.
// Add keys here, consume via context.l10n or AppLocalizations.of(context).

import 'package:flutter/material.dart';

// ─── Supported locales ─────────────────────────────────────────────────────────
enum AppLanguage { en, fr }

// ─── String tables ─────────────────────────────────────────────────────────────
const Map<String, Map<AppLanguage, String>> _strings = {
  // App
  'appName': {
    AppLanguage.en: 'Neno SmartLife',
    AppLanguage.fr: 'Neno SmartLife'
  },
  'tagline': {
    AppLanguage.en: 'General Electronics',
    AppLanguage.fr: 'Électronique Générale'
  },

  // Onboarding
  'onboarding1Title': {
    AppLanguage.en: 'Discover Smart Electronics',
    AppLanguage.fr: 'Découvrez l\'Électronique Intelligente',
  },
  'onboarding1Subtitle': {
    AppLanguage.en:
        'Browse hundreds of phones, TVs, accessories and more — all in one place.',
    AppLanguage.fr:
        'Parcourez des centaines de téléphones, TV, accessoires et plus — tout en un.',
  },
  'onboarding2Title': {
    AppLanguage.en: 'Save & Compare Favourites',
    AppLanguage.fr: 'Sauvegardez & Comparez vos Favoris',
  },
  'onboarding2Subtitle': {
    AppLanguage.en:
        'Shortlist products you love and share them with ease. No account needed.',
    AppLanguage.fr:
        'Sélectionnez les produits que vous aimez et partagez-les facilement. Sans compte.',
  },
  'onboarding3Title': {
    AppLanguage.en: 'Request & Get Delivered',
    AppLanguage.fr: 'Commandez & Faites-vous Livrer',
  },
  'onboarding3Subtitle': {
    AppLanguage.en:
        'Submit your order, chat with us directly, and we\'ll sort out payment and delivery.',
    AppLanguage.fr:
        'Passez votre commande, discutez avec nous, et nous nous occupons du paiement et de la livraison.',
  },
  'getStarted': {AppLanguage.en: 'Get Started', AppLanguage.fr: 'Commencer'},
  'next': {AppLanguage.en: 'Next', AppLanguage.fr: 'Suivant'},
  'skip': {AppLanguage.en: 'Skip', AppLanguage.fr: 'Passer'},

  // Home
  'searchHint': {
    AppLanguage.en: 'Search products...',
    AppLanguage.fr: 'Rechercher des produits...',
  },
  'allCategories': {AppLanguage.en: 'All', AppLanguage.fr: 'Tout'},
  'imInterested': {
    AppLanguage.en: "I'm Interested",
    AppLanguage.fr: 'Je suis Intéressé(e)'
  },
  'addToCart': {
    AppLanguage.en: 'Add to Cart',
    AppLanguage.fr: 'Ajouter au Panier'
  },
  'noProductsFound': {
    AppLanguage.en: 'No products found',
    AppLanguage.fr: 'Aucun produit trouvé',
  },

  // Badges
  'badgeNew': {AppLanguage.en: 'NEW', AppLanguage.fr: 'NEUF'},
  'badgeHot': {AppLanguage.en: 'HOT', AppLanguage.fr: 'POPULAIRE'},
  'badgeSale': {AppLanguage.en: 'SALE', AppLanguage.fr: 'PROMO'},

  // Condition
  'conditionNew': {AppLanguage.en: 'New', AppLanguage.fr: 'Neuf'},
  'conditionRefurbished': {
    AppLanguage.en: 'Refurbished',
    AppLanguage.fr: 'Reconditionné'
  },

  // Stock
  'inStock': {AppLanguage.en: 'In Stock', AppLanguage.fr: 'En Stock'},
  'limitedStock': {
    AppLanguage.en: 'Limited Stock',
    AppLanguage.fr: 'Stock Limité'
  },
  'outOfStock': {
    AppLanguage.en: 'Out of Stock',
    AppLanguage.fr: 'Rupture de Stock'
  },

  // Product Detail
  'backTo': {AppLanguage.en: 'Back to', AppLanguage.fr: 'Retour à'},
  'color': {AppLanguage.en: 'Color:', AppLanguage.fr: 'Couleur :'},
  'keySpecs': {
    AppLanguage.en: 'Key Specifications',
    AppLanguage.fr: 'Caractéristiques Principales'
  },
  'frequentlyBought': {
    AppLanguage.en: 'Frequently Bought Together',
    AppLanguage.fr: 'Fréquemment Achetés Ensemble',
  },
  'reviews': {AppLanguage.en: 'reviews', AppLanguage.fr: 'avis'},
  'condition': {AppLanguage.en: 'Condition:', AppLanguage.fr: 'État :'},

  // Nav
  'navHome': {AppLanguage.en: 'Home', AppLanguage.fr: 'Accueil'},
  'navCategories': {AppLanguage.en: 'Categories', AppLanguage.fr: 'Catégories'},
  'navOrders': {AppLanguage.en: 'Orders', AppLanguage.fr: 'Commandes'},
  'navAccount': {AppLanguage.en: 'Account', AppLanguage.fr: 'Compte'},

  // Promo banners
  'promo1Title': {
    AppLanguage.en: 'New Arrivals This Week',
    AppLanguage.fr: 'Nouvelles Arrivées Cette Semaine',
  },
  'promo1Sub': {
    AppLanguage.en: 'Latest phones, TVs & accessories just landed.',
    AppLanguage.fr: 'Téléphones, TV et accessoires tout juste arrivés.',
  },
  'promo2Title': {
    AppLanguage.en: 'Quality Refurbished Deals',
    AppLanguage.fr: 'Reconditionnés de Qualité',
  },
  'promo2Sub': {
    AppLanguage.en: 'Certified pre-owned electronics at great prices.',
    AppLanguage.fr: 'Électroniques reconditionnés certifiés à prix réduit.',
  },
  'promo3Title': {
    AppLanguage.en: 'Chat & Order Easily',
    AppLanguage.fr: 'Discutez & Commandez Facilement',
  },
  'promo3Sub': {
    AppLanguage.en: 'Tell us what you need — we handle the rest.',
    AppLanguage.fr:
        'Dites-nous ce dont vous avez besoin — on s\'occupe du reste.',
  },
  'shopNow': {AppLanguage.en: 'Shop Now', AppLanguage.fr: 'Acheter Maintenant'},

  // ── Cart ──────────────────────────────────────────────────────────────────
  'cartTitle': {AppLanguage.en: 'Shopping Cart', AppLanguage.fr: 'Panier'},
  'yourCart': {AppLanguage.en: 'Your Cart', AppLanguage.fr: 'Votre Panier'},
  'cartEmpty': {
    AppLanguage.en: 'Your cart is empty',
    AppLanguage.fr: 'Votre panier est vide',
  },
  'cartEmptySub': {
    AppLanguage.en: 'Add products you want to request.',
    AppLanguage.fr: 'Ajoutez des produits que vous souhaitez demander.',
  },
  'cartSummary': {AppLanguage.en: 'Summary', AppLanguage.fr: 'Récapitulatif'},
  'cartItems': {AppLanguage.en: 'Items', AppLanguage.fr: 'Articles'},
  'cartTotal': {AppLanguage.en: 'Total', AppLanguage.fr: 'Total'},
  'cartPaymentNote': {
    AppLanguage.en:
        'Payment and delivery will be arranged after request submission.',
    AppLanguage.fr:
        'Le paiement et la livraison seront arrangés après la soumission de la demande.',
  },
  'requestPurchase': {
    AppLanguage.en: 'Request Purchase',
    AppLanguage.fr: 'Demander l\'Achat',
  },
  'removeItem': {AppLanguage.en: 'Remove', AppLanguage.fr: 'Supprimer'},
  'cartVariant': {AppLanguage.en: 'Variant', AppLanguage.fr: 'Variante'},

  // ── Favourites ────────────────────────────────────────────────────────────
  'favTitle': {AppLanguage.en: 'My Favorites', AppLanguage.fr: 'Mes Favoris'},
  'savedItems': {
    AppLanguage.en: 'Saved Items',
    AppLanguage.fr: 'Éléments Sauvegardés'
  },
  'favEmpty': {
    AppLanguage.en: 'No saved items yet',
    AppLanguage.fr: 'Aucun élément sauvegardé',
  },
  'favEmptySub': {
    AppLanguage.en: 'Tap the heart on any product to save it here.',
    AppLanguage.fr:
        'Appuyez sur le cœur d\'un produit pour le sauvegarder ici.',
  },
  'myWishlist': {
    AppLanguage.en: 'My Wishlist',
    AppLanguage.fr: 'Ma Liste',
  },
  'notifyMe': {AppLanguage.en: 'Notify Me', AppLanguage.fr: 'Me Notifier'},
  'items': {AppLanguage.en: 'Items', AppLanguage.fr: 'Articles'},

  // ── Orders ────────────────────────────────────────────────────────────────
  'ordersTitle': {
    AppLanguage.en: 'Orders & Purchase History',
    AppLanguage.fr: 'Commandes & Historique',
  },
  'ordersPending': {AppLanguage.en: 'Pending', AppLanguage.fr: 'En Cours'},
  'ordersCompleted': {AppLanguage.en: 'Completed', AppLanguage.fr: 'Terminées'},
  'ordersEmpty': {
    AppLanguage.en: 'No orders yet',
    AppLanguage.fr: 'Aucune commande',
  },
  'ordersEmptySub': {
    AppLanguage.en: 'Your purchase history will appear here.',
    AppLanguage.fr: 'Votre historique d\'achats apparaîtra ici.',
  },
  'viewReceipt': {
    AppLanguage.en: 'View Receipt',
    AppLanguage.fr: 'Voir le Reçu'
  },
  'buyAgain': {AppLanguage.en: 'Buy Again', AppLanguage.fr: 'Racheter'},
  'orderStatusCompleted': {
    AppLanguage.en: 'Completed',
    AppLanguage.fr: 'Terminée'
  },
  'orderStatusPending': {AppLanguage.en: 'Pending', AppLanguage.fr: 'En Cours'},
  'orderStatusProcessing': {
    AppLanguage.en: 'Processing',
    AppLanguage.fr: 'En Traitement'
  },
  'orderPurchased': {AppLanguage.en: 'Purchased:', AppLanguage.fr: 'Acheté :'},
  'orderTotal': {AppLanguage.en: 'Total', AppLanguage.fr: 'Total'},

  // ── Account ───────────────────────────────────────────────────────────────
  'accountTitle': {AppLanguage.en: 'Account', AppLanguage.fr: 'Compte'},
  'accountMyOrders': {
    AppLanguage.en: 'My Orders',
    AppLanguage.fr: 'Mes Commandes'
  },
  'accountInTransit': {
    AppLanguage.en: 'In Transit',
    AppLanguage.fr: 'En Transit',
  },
  'accountMyWishlist': {
    AppLanguage.en: 'My Wishlist',
    AppLanguage.fr: 'Ma Liste de Souhaits',
  },
  'accountItemsSaved': {
    AppLanguage.en: 'Items Saved',
    AppLanguage.fr: 'Articles Sauvegardés',
  },
  'accountShipping': {
    AppLanguage.en: 'Shipping Addresses',
    AppLanguage.fr: 'Adresses de Livraison',
  },
  'accountShippingSub': {
    AppLanguage.en: 'Manage locations',
    AppLanguage.fr: 'Gérer les adresses',
  },
  'accountPayment': {
    AppLanguage.en: 'Payment Methods',
    AppLanguage.fr: 'Moyens de Paiement',
  },
  'accountPaymentSub': {
    AppLanguage.en: 'Visa ending in 4242',
    AppLanguage.fr: 'Visa se terminant par 4242',
  },
  'accountPreferences': {
    AppLanguage.en: 'PREFERENCES',
    AppLanguage.fr: 'PRÉFÉRENCES',
  },
  'accountLanguage': {AppLanguage.en: 'Language', AppLanguage.fr: 'Langue'},
  'accountLanguageVal': {AppLanguage.en: 'English', AppLanguage.fr: 'Français'},
  'accountDarkMode': {
    AppLanguage.en: 'Dark Mode',
    AppLanguage.fr: 'Mode Sombre'
  },
  'accountSupport': {AppLanguage.en: 'SUPPORT', AppLanguage.fr: 'SUPPORT'},
  'accountHelpCenter': {
    AppLanguage.en: 'Help Center',
    AppLanguage.fr: 'Centre d\'Aide',
  },
  'accountContactAdmin': {
    AppLanguage.en: 'Contact Admin',
    AppLanguage.fr: 'Contacter l\'Admin',
  },
  'accountClearHistory': {
    AppLanguage.en: 'Clear My History',
    AppLanguage.fr: 'Effacer Mon Historique',
  },
  'accountClearHistoryConfirmTitle': {
    AppLanguage.en: 'Clear History?',
    AppLanguage.fr: 'Effacer l\'Historique ?',
  },
  'accountClearHistoryConfirmBody': {
    AppLanguage.en:
        'This will permanently remove all your orders, saved items, and cart contents. This cannot be undone.',
    AppLanguage.fr:
        'Cela supprimera définitivement toutes vos commandes, articles sauvegardés et le contenu de votre panier. Cette action est irréversible.',
  },
  'accountClearHistoryConfirm': {
    AppLanguage.en: 'Clear',
    AppLanguage.fr: 'Effacer'
  },
  'cancel': {AppLanguage.en: 'Cancel', AppLanguage.fr: 'Annuler'},
  'comingSoon': {
    AppLanguage.en: 'Coming soon',
    AppLanguage.fr: 'Bientôt disponible'
  },
};

// ─── Accessor ──────────────────────────────────────────────────────────────────
class AppLocalizations {
  final AppLanguage language;
  const AppLocalizations(this.language);

  static AppLocalizations of(BuildContext context) {
    return _InheritedLocale.of(context).localizations;
  }

  String tr(String key) {
    return _strings[key]?[language] ?? _strings[key]?[AppLanguage.en] ?? key;
  }

  // Convenience getters — avoids magic strings at call sites
  String get appName => tr('appName');
  String get tagline => tr('tagline');
  String get onboarding1Title => tr('onboarding1Title');
  String get onboarding1Subtitle => tr('onboarding1Subtitle');
  String get onboarding2Title => tr('onboarding2Title');
  String get onboarding2Subtitle => tr('onboarding2Subtitle');
  String get onboarding3Title => tr('onboarding3Title');
  String get onboarding3Subtitle => tr('onboarding3Subtitle');
  String get getStarted => tr('getStarted');
  String get next => tr('next');
  String get skip => tr('skip');
  String get searchHint => tr('searchHint');
  String get allCategories => tr('allCategories');
  String get imInterested => tr('imInterested');
  String get addToCart => tr('addToCart');
  String get noProductsFound => tr('noProductsFound');
  String get badgeNew => tr('badgeNew');
  String get badgeHot => tr('badgeHot');
  String get badgeSale => tr('badgeSale');
  String get conditionNew => tr('conditionNew');
  String get conditionRefurbished => tr('conditionRefurbished');
  String get inStock => tr('inStock');
  String get limitedStock => tr('limitedStock');
  String get outOfStock => tr('outOfStock');
  String get backTo => tr('backTo');
  String get color => tr('color');
  String get keySpecs => tr('keySpecs');
  String get frequentlyBought => tr('frequentlyBought');
  String get reviews => tr('reviews');
  String get condition => tr('condition');
  String get navHome => tr('navHome');
  String get navCategories => tr('navCategories');
  String get navOrders => tr('navOrders');
  String get navAccount => tr('navAccount');
  String get promo1Title => tr('promo1Title');
  String get promo1Sub => tr('promo1Sub');
  String get promo2Title => tr('promo2Title');
  String get promo2Sub => tr('promo2Sub');
  String get promo3Title => tr('promo3Title');
  String get promo3Sub => tr('promo3Sub');
  String get shopNow => tr('shopNow');

  // Cart
  String get cartTitle => tr('cartTitle');
  String get yourCart => tr('yourCart');
  String get cartEmpty => tr('cartEmpty');
  String get cartEmptySub => tr('cartEmptySub');
  String get cartSummary => tr('cartSummary');
  String get cartItems => tr('cartItems');
  String get cartTotal => tr('cartTotal');
  String get cartPaymentNote => tr('cartPaymentNote');
  String get requestPurchase => tr('requestPurchase');
  String get removeItem => tr('removeItem');
  String get cartVariant => tr('cartVariant');

  // Favourites
  String get favTitle => tr('favTitle');
  String get savedItems => tr('savedItems');
  String get favEmpty => tr('favEmpty');
  String get favEmptySub => tr('favEmptySub');
  String get myWishlist => tr('myWishlist');
  String get notifyMe => tr('notifyMe');
  String get items => tr('items');

  // Orders
  String get ordersTitle => tr('ordersTitle');
  String get ordersPending => tr('ordersPending');
  String get ordersCompleted => tr('ordersCompleted');
  String get ordersEmpty => tr('ordersEmpty');
  String get ordersEmptySub => tr('ordersEmptySub');
  String get viewReceipt => tr('viewReceipt');
  String get buyAgain => tr('buyAgain');
  String get orderStatusCompleted => tr('orderStatusCompleted');
  String get orderStatusPending => tr('orderStatusPending');
  String get orderStatusProcessing => tr('orderStatusProcessing');
  String get orderPurchased => tr('orderPurchased');
  String get orderTotal => tr('orderTotal');

  // Account
  String get accountTitle => tr('accountTitle');
  String get accountMyOrders => tr('accountMyOrders');
  String get accountInTransit => tr('accountInTransit');
  String get accountMyWishlist => tr('accountMyWishlist');
  String get accountItemsSaved => tr('accountItemsSaved');
  String get accountShipping => tr('accountShipping');
  String get accountShippingSub => tr('accountShippingSub');
  String get accountPayment => tr('accountPayment');
  String get accountPaymentSub => tr('accountPaymentSub');
  String get accountPreferences => tr('accountPreferences');
  String get accountLanguage => tr('accountLanguage');
  String get accountLanguageVal => tr('accountLanguageVal');
  String get accountDarkMode => tr('accountDarkMode');
  String get accountSupport => tr('accountSupport');
  String get accountHelpCenter => tr('accountHelpCenter');
  String get accountContactAdmin => tr('accountContactAdmin');
  String get accountClearHistory => tr('accountClearHistory');
  String get accountClearHistoryConfirmTitle =>
      tr('accountClearHistoryConfirmTitle');
  String get accountClearHistoryConfirmBody =>
      tr('accountClearHistoryConfirmBody');
  String get accountClearHistoryConfirm => tr('accountClearHistoryConfirm');
  String get cancel => tr('cancel');
  String get comingSoon => tr('comingSoon');
}

// ─── InheritedWidget ───────────────────────────────────────────────────────────
class _InheritedLocale extends InheritedWidget {
  final AppLocalizations localizations;

  const _InheritedLocale({
    required this.localizations,
    required super.child,
  });

  static _InheritedLocale of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<_InheritedLocale>();
    assert(result != null, 'No _InheritedLocale found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(_InheritedLocale old) =>
      localizations.language != old.localizations.language;
}

/// Wrap your app (or any subtree) with this to provide localizations.
class LocaleProvider extends StatefulWidget {
  final Widget child;
  const LocaleProvider({super.key, required this.child});

  @override
  State<LocaleProvider> createState() => LocaleProviderState();

  /// Access the provider state from anywhere below in the tree.
  static LocaleProviderState of(BuildContext context) {
    return context.findAncestorStateOfType<LocaleProviderState>()!;
  }
}

class LocaleProviderState extends State<LocaleProvider> {
  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;

  void toggle() {
    setState(() {
      _language = _language == AppLanguage.en ? AppLanguage.fr : AppLanguage.en;
    });
  }

  void setLanguage(AppLanguage lang) {
    if (lang != _language) setState(() => _language = lang);
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedLocale(
      localizations: AppLocalizations(_language),
      child: widget.child,
    );
  }
}

// ─── Extension shorthand ───────────────────────────────────────────────────────
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
