import 'package:go_router/go_router.dart';
import 'package:gta_app/src/commons/views/splashscreen.dart';
import 'package:gta_app/src/features/common_features/auth/views/login_screen.dart';
import 'package:gta_app/src/features/common_features/auth/views/otp_screen.dart';
import 'package:gta_app/src/features/buyer/home/views/buyer_home_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/edit_profile_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/manage_addresses_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/add_address_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_verification_screen.dart';
import 'package:gta_app/src/features/buyer/profile/views/buyer_help_faq_screen.dart';
import 'package:gta_app/src/features/seller/dashboard/views/seller_dashboard_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_personal_details_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_business_address_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_verification_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_help_center_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_policies_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_bank_details_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_store_profile_screen.dart';
import 'package:gta_app/src/features/seller/profile/views/seller_onboarding_screen.dart';
import 'package:gta_app/src/features/seller/earnings/views/seller_earnings_screen.dart';
import 'package:gta_app/src/features/seller/product/views/seller_product_details_screen.dart';
import 'package:gta_app/src/features/seller/product/views/add_product_screen.dart';
import 'package:gta_app/src/features/seller/product/views/edit_product_screen.dart';
import 'package:gta_app/src/models/product_model.dart';
import 'package:gta_app/src/features/seller/orders/views/seller_order_list_screen.dart';
import 'package:gta_app/src/features/seller/orders/views/seller_order_details_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/complaints_list_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/create_complaint_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/complaint_details_screen.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_complaints_list_screen.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_create_complaint_screen.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_complaint_details_screen.dart';
import 'package:gta_app/src/features/buyer/home/views/buyer_search_screen.dart';
import 'package:gta_app/src/features/buyer/product/views/buyer_product_details_screen.dart';
import 'package:gta_app/src/features/buyer/wishlist/views/buyer_wishlist_screen.dart';
import 'package:gta_app/src/features/common_features/chatbot/views/chatbot_screen.dart';
import 'package:gta_app/src/models/complaint_model.dart';

final GoRouter router = GoRouter(
  initialLocation: Splashscreen.routePath,
  routes: [
    // Splash Screen
    GoRoute(
      path: Splashscreen.routePath,
      builder: (context, state) => const Splashscreen(),
    ),

    // Auth Routes
    GoRoute(
      path: LoginScreen.routePath,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: OtpScreen.routePath,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        // If no extra data, redirect to login
        if (extra == null || extra['phone'] == null) {
          return const LoginScreen();
        }
        return OtpScreen(
          phone: extra['phone'] as String,
          userType: extra['userType'] as String? ?? 'buyer',
        );
      },
    ),

    // Buyer Routes
    GoRoute(
      path: BuyerHomeScreen.routePath,
      builder: (context, state) => const BuyerHomeScreen(),
    ),
    GoRoute(
      path: BuyerSearchScreen.routePath,
      builder: (context, state) => const BuyerSearchScreen(),
    ),
    GoRoute(
      path: BuyerProductDetailsScreen.routePath,
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return BuyerProductDetailsScreen(productId: productId);
      },
    ),
    GoRoute(
      path: EditProfileScreen.routePath,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: ManageAddressesScreen.routePath,
      builder: (context, state) => const ManageAddressesScreen(),
    ),
    GoRoute(
      path: AddAddressScreen.routePath,
      builder: (context, state) => const AddAddressScreen(),
    ),
    GoRoute(
      path: BuyerVerificationScreen.routePath,
      builder: (context, state) => const BuyerVerificationScreen(),
    ),
    GoRoute(
      path: BuyerHelpFaqScreen.routePath,
      builder: (context, state) => const BuyerHelpFaqScreen(),
    ),
    GoRoute(
      path: BuyerWishlistScreen.routePath,
      builder: (context, state) => const BuyerWishlistScreen(),
    ),

    // Buyer Complaints
    GoRoute(
      path: '/buyer/complaints',
      builder: (context, state) => const ComplaintsListScreen(),
    ),
    GoRoute(
      path: '/buyer/complaint/create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final category = extra?['category'] as String? ?? 'General';
        return CreateComplaintScreen(
          categoryKey: category.toLowerCase(),
          categoryLabel: category,
        );
      },
    ),
    GoRoute(
      path: '/buyer/complaint/details',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ComplaintDetailsScreen(
          complaintId: extra?['complaintId'] as String,
          complaint: extra?['complaint'] as Complaint?,
        );
      },
    ),
    GoRoute(
      path: ChatbotScreen.buyerRoutePath,
      builder: (context, state) => const ChatbotScreen(userType: 'buyer'),
    ),

    // Seller Routes
    GoRoute(
      path: SellerDashboardScreen.routePath,
      builder: (context, state) => const SellerDashboardScreen(),
    ),
    GoRoute(
      path: SellerPersonalDetailsScreen.routePath,
      builder: (context, state) => const SellerPersonalDetailsScreen(),
    ),
    GoRoute(
      path: SellerBusinessAddressScreen.routePath,
      builder: (context, state) => const SellerBusinessAddressScreen(),
    ),
    GoRoute(
      path: SellerVerificationScreen.routePath,
      builder: (context, state) => const SellerVerificationScreen(),
    ),
    GoRoute(
      path: SellerHelpCenterScreen.routePath,
      builder: (context, state) => const SellerHelpCenterScreen(),
    ),
    GoRoute(
      path: SellerPoliciesScreen.routePath,
      builder: (context, state) => const SellerPoliciesScreen(),
    ),
    GoRoute(
      path: SellerBankDetailsScreen.routePath,
      builder: (context, state) => const SellerBankDetailsScreen(),
    ),
    GoRoute(
      path: SellerStoreProfileScreen.routePath,
      builder: (context, state) => const SellerStoreProfileScreen(),
    ),
    GoRoute(
      path: SellerOnboardingScreen.routePath,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SellerOnboardingScreen(
          initialPage: extra?['initialPage'] as int? ?? 0,
        );
      },
    ),
    GoRoute(
      path: SellerEarningsScreen.routePath,
      builder: (context, state) => const SellerEarningsScreen(),
    ),

    // Seller Complaints
    GoRoute(
      path: SellerComplaintsListScreen.routePath,
      builder: (context, state) => const SellerComplaintsListScreen(),
    ),
    GoRoute(
      path: '/seller/complaint/create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SellerCreateComplaintScreen(
          category: extra?['category'] as String? ?? 'General',
        );
      },
    ),
    GoRoute(
      path: SellerComplaintDetailsScreen.routePath,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SellerComplaintDetailsScreen(
          complaintId: extra?['complaintId'] as String,
          complaint: extra?['complaint'] as Complaint?,
        );
      },
    ),
    GoRoute(
      path: ChatbotScreen.sellerRoutePath,
      builder: (context, state) => const ChatbotScreen(userType: 'seller'),
    ),

    // Seller Orders
    GoRoute(
      path: SellerOrderListScreen.routePath,
      builder: (context, state) => const SellerOrderListScreen(),
    ),
    GoRoute(
      path: SellerOrderDetailsScreen.routePath,
      builder: (context, state) {
        final orderId = state.extra as String;
        return SellerOrderDetailsScreen(orderId: orderId);
      },
    ),

    // Seller Add Product (also used for duplicate when extra is a Product)
    GoRoute(
      path: AddProductScreen.routePath,
      builder: (context, state) => AddProductScreen(
        duplicateFrom: state.extra is Product ? state.extra as Product : null,
      ),
    ),

    // Seller Edit Product
    GoRoute(
      path: EditProductScreen.routePath,
      builder: (context, state) {
        final product = state.extra as Product;
        return EditProductScreen(product: product);
      },
    ),

    // Seller Product Details
    GoRoute(
      path: SellerProductDetailsScreen.routePath,
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return SellerProductDetailsScreen(productId: productId);
      },
    ),
  ],
);
