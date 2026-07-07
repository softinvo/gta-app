import 'package:gta_app/src/res/base.dart';

class Endpoints {
  static const String baseUrl = BasePaths.baseUrl;

  // Auth endpoints
  static const String sendOTP = '${baseUrl}user/sendotp';
  static const String verifyOTP = '${baseUrl}user/loginphone';
  static const String googleLogin = '${baseUrl}user/google-login';

  //Profile
  static const String storage = "${baseUrl}storage/upload";
  static const String sellerProfile = "${baseUrl}seller/profile";
  static const String getProfile = "${baseUrl}seller/profile";
  static const String editProfile = "${baseUrl}seller/profile";
  static const String sellerAddBank = "${baseUrl}seller/add-bank";
  static const String sellerProfileStats = "${baseUrl}seller/profile/stats";

  // Buyer Profile
  static const String getBuyerProfile = "${baseUrl}buyer/profile";
  static const String updateBuyerProfile = "${baseUrl}buyer/profile";
  static const String getBuyerAddresses = "${baseUrl}buyer/address";
  static const String addBuyerAddress = "${baseUrl}buyer/address/add";
  static String removeBuyerAddress(String addressId) =>
      "${baseUrl}buyer/address/$addressId";
  static String markAddressPrimary(String addressId) =>
      "${baseUrl}buyer/address/$addressId/primary";

  // Buyer Complaints
  static const String createBuyerComplaint = "${baseUrl}buyer/complaint/add";
  static const String getBuyerComplaints = "${baseUrl}buyer/complaints";
  static const String getBuyerComplaintStats =
      "${baseUrl}buyer/complaint/stats";
  static String getBuyerComplaintDetails(String id) =>
      "${baseUrl}buyer/complaint/$id";
  static String sendBuyerComplaintMessage(String id) =>
      "${baseUrl}buyer/complaint/$id/message";
  static const String getBuyerChatbot = "${baseUrl}buyer/chatbot";
  //membership
  static const String createMembershipPayment =
      "${baseUrl}membership/create-payment";
  static const String verifyMembershipPayment =
      "${baseUrl}membership/verify-payment";
  static const String paymentFailed = "${baseUrl}membership/payment-failed";
  // Customer Review
  static const String getReviews = "${baseUrl}ratings/partner-warehouse";
  static const String getWarehouseReviews =
      "${baseUrl}ratings/particular-warehouse";

  // KYC
  static const String uploadKYC = "${baseUrl}kyc/upload";
  static const String getKYC = "${baseUrl}kyc/status";

  // Complaints (Seller)
  static const String getComplaints = "${baseUrl}seller/complaints";
  static const String createComplaint = "${baseUrl}seller/complaint/add";
  static const String getSellerComplaintStats =
      "${baseUrl}seller/complaint/stats";
  static String getSellerComplaintDetails(String id) =>
      "${baseUrl}seller/complaint/$id";
  static String sendSellerComplaintMessage(String id) =>
      "${baseUrl}seller/complaint/$id/message";
  static const String getSellerChatbot = "${baseUrl}seller/chatbot";

  //Warehouse
  static const String createWarehouse = "${baseUrl}business/create-profile";
  static const String getWarehouses =
      "${baseUrl}business/fetch-partner-profile";
  static const String getWarehouseDetails = "${baseUrl}business/fetch-profile";
  static const String updateWarehouseStatus =
      "${baseUrl}business/update-profile";

  static const String updateWarehouse = "${baseUrl}business/update-profile";
  static const String deleteWarehouse = "${baseUrl}business/delete-profile";

  // Bank
  static const String addBank = "${baseUrl}bank-details";
  static const String getBank = "${baseUrl}bank-details";
  static const String updateBank = "${baseUrl}bank-detail";
  static const String deleteBank = "${baseUrl}bank-detail";
  static const String getDetailsByIFSC = "${baseUrl}bank-details/by-ifsc";

  // Earning
  static const String getEarningSummary = "${baseUrl}earning-data";
  static const String getWithdrawalHistory = "${baseUrl}withdraw-history";
  static const String getTransactionHistory = "${baseUrl}earning-history";

  // Booking
  static const String getActiveBooking = "${baseUrl}bookings/partner-active";
  static const String getCompletedBooking =
      "${baseUrl}bookings/partner-completed";
  static const String getBookingDetails = "${baseUrl}booking/details-partner";

  // Recover
  static const String verifyOTPForRecovery =
      "${baseUrl}partner/reset/verify-otp";
  static const String updatePassword = "${baseUrl}partner/reset-password-sms";
  static const String resetLinkOnEmail = "${baseUrl}partner/reset-link-email";

  // Seller Products
  static const String addProduct = "${baseUrl}seller/product/add";
  static const String getSellerProducts = "${baseUrl}seller/products";
  static String getProductById(String id) =>
      "${baseUrl}seller/product/$id/details";
  static String deleteProduct(String id) => "${baseUrl}seller/product/$id";
  static String updateProduct(String id) => "${baseUrl}seller/product/$id";
  static String updateVariantByColor(String productId, String colorCode) =>
      "${baseUrl}seller/product/$productId/update-variant-by-color/${Uri.encodeComponent(colorCode)}";

  // Categories
  static const String getCategories = "${baseUrl}categories";
  static String getSubcategories(String categoryId) =>
      "${baseUrl}categories/$categoryId/subcategories";
  static String getProductTypes(String subcategoryId) =>
      "${baseUrl}categories/subcategories/$subcategoryId/product-types";

  // Seller Orders
  static const String sellerOrderList = "${baseUrl}order/seller/list";
  static const String sellerOrderStats = "${baseUrl}order/seller/stats/orders";
  static String sellerOrderDetails(String orderId) =>
      "${baseUrl}order/seller/$orderId";
  static String updateOrderStatus(String orderId) =>
      "${baseUrl}order/seller/$orderId/status";

  // Seller Quotations
  static const String sellerQuotationList = "${baseUrl}quotation/seller/list";
  static const String sellerQuotationStats = "${baseUrl}quotation/seller/stats";
  static String sellerQuotationDetails(String id) =>
      "${baseUrl}quotation/seller/$id";
  static String finalizeQuotation(String id) =>
      "${baseUrl}quotation/seller/$id/finalize";
  static const String cancelQuotation = "${baseUrl}quotation/seller/cancel";

  // Buyer Quotations
  static const String createQuotation = "${baseUrl}quotation/add-new";
  static const String buyerQuotationList = "${baseUrl}quotation/buyer/list";
  static const String buyerQuotationStats = "${baseUrl}quotation/buyer/stats";
  static String buyerQuotationDetails(String id) =>
      "${baseUrl}quotation/buyer/$id";
  static String cancelBuyerQuotation(String id) =>
      "${baseUrl}quotation/buyer/$id/cancel";

  // Buyer Orders
  static const String createOrder = "${baseUrl}order/create";
  static const String verifyOrderPayment = "${baseUrl}order/verify-payment";
  static const String buyerOrderList = "${baseUrl}order/buyer/list";
  static String buyerOrderDetails(String orderId) =>
      "${baseUrl}order/$orderId";
  static String cancelBuyerOrder(String orderId) =>
      "${baseUrl}order/$orderId/cancel";

  // FCM Token
  static const String buyerFcmToken = "${baseUrl}buyer/fcm-token";
  static const String sellerFcmToken = "${baseUrl}seller/fcm-token";

  // Chat Server (port 5002 — no auth)
  static const String chatSocketUrl = BasePaths.chatSocketUrl;
  static const String chatUserInfo =
      '${BasePaths.chatRestUrl}api/chat/user-info';
  static const String chatConversations =
      '${BasePaths.chatRestUrl}api/chat/conversations';
  static const String chatMessages =
      '${BasePaths.chatRestUrl}api/chat/messages';
  static const String chatUploadUrl =
      '${BasePaths.chatRestUrl}api/chat/upload-url';
  static String chatDeleteMessage(String messageId) =>
      '${BasePaths.chatRestUrl}api/chat/message/$messageId';

  // Buyer Products
  static const String buyerProductCollections =
      "${baseUrl}buyer/product/collections";
  static String buyerProductDetails(String productId) =>
      "${baseUrl}buyer/product/$productId/details";
  static String buyerProductSearch({
    required String query,
    String? category,
    String? subCategory,
    String? productType,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'newest',
    int page = 1,
    int limit = 20,
  }) {
    final params = <String, String>{
      'search': query,
      'sortBy': sortBy,
      'page': '$page',
      'limit': '$limit',
      if (category != null) 'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      if (productType != null) 'productType': productType,
      if (minPrice != null) 'minPrice': '${minPrice.toInt()}',
      if (maxPrice != null) 'maxPrice': '${maxPrice.toInt()}',
    };
    final query_ = Uri(queryParameters: params).query;
    return "${baseUrl}buyer/products?$query_";
  }
}
