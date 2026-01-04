import 'package:gta_app/src/res/base.dart';

class Endpoints {
  static const String baseUrl = BasePaths.baseUrl;
  static const String sendOTP = '$baseUrl/partner/sendOTP';
  static const String verifyOTP = '$baseUrl/partner/loginPhone';
  static const String loginEmail = '$baseUrl/partner/loginEmail';
  static const String updateSocketId = '$baseUrl/partner/update-chat-socket';
  static const String signUp = '$baseUrl/partner/signup';
  //Profile
  static const String storage = "$baseUrl/storage/upload";
  static const String getProfile = "${baseUrl}partner/profile";
  static const String editProfile = "${baseUrl}partner/profile";
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

  // Complaints
  static const String getComplaints = "${baseUrl}partner/complaints";
  static const String createComplaint = "${baseUrl}partner/complaints";

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
}
