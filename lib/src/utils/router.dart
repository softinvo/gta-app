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
import 'package:gta_app/src/features/buyer/complaint/views/complaints_list_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/create_complaint_screen.dart';
import 'package:gta_app/src/features/buyer/complaint/views/complaint_details_screen.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_complaints_list_screen.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_create_complaint_screen.dart';
import 'package:gta_app/src/features/seller/complaint/views/seller_complaint_details_screen.dart';
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

    // Buyer Complaints
    GoRoute(
      path: '/buyer/complaints',
      builder: (context, state) => const ComplaintsListScreen(),
    ),
    GoRoute(
      path: '/buyer/complaint/create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CreateComplaintScreen(
          category: extra?['category'] as String? ?? 'General',
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
  ],
);
