import 'package:gta_app/src/res/base.dart';

class Endpoints {
  static const String baseUrl = BasePaths.baseUrl;

  // Auth endpoints
  static const String sendOTP = '${baseUrl}user/sendotp';
  static const String verifyOTP = '${baseUrl}user/loginphone';

  //Profile
  static const String storage = "$baseUrl/storage/upload";
  static const String getProfile = "${baseUrl}partner/profile";
  static const String editProfile = "${baseUrl}partner/profile";

  // Buyer Profile
  static const String getBuyerProfile = "${baseUrl}buyer/profile";
  static const String updateBuyerProfile = "${baseUrl}buyer/profile";
  static const String getBuyerAddresses = "${baseUrl}buyer/address";
  static const String addBuyerAddress = "${baseUrl}buyer/address/add";
  static String removeBuyerAddress(String addressId) =>
      "${baseUrl}buyer/address/$addressId";

  // Buyer Complaints
  static const String createBuyerComplaint = "${baseUrl}buyer/complaint/add";
  static const String getBuyerComplaints = "${baseUrl}buyer/complaints";
  static const String getBuyerComplaintStats =
      "${baseUrl}buyer/complaint/stats";
  static String getBuyerComplaintDetails(String id) =>
      "${baseUrl}buyer/complaint/$id";
  static String sendBuyerComplaintMessage(String id) =>
      "${baseUrl}buyer/complaint/$id/message";
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

  // Categories
  static const String getCategories = "${baseUrl}categories";
  static String getSubcategories(String categoryId) =>
      "${baseUrl}categories/$categoryId/subcategories";
  static String getProductTypes(String subcategoryId) =>
      "${baseUrl}categories/subcategories/$subcategoryId/product-types";
}
