import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:picturo_app/responses/allusers_response.dart';
import 'package:picturo_app/responses/avatar_response.dart';
import 'package:picturo_app/responses/bank_account_details.dart';
import 'package:picturo_app/responses/books_response.dart';
import 'package:picturo_app/responses/chat_requests_response.dart';
import 'package:picturo_app/responses/friends_response.dart';
import 'package:picturo_app/responses/games_response.dart';
import 'package:picturo_app/responses/language_response.dart';
import 'package:picturo_app/responses/message_response.dart';
import 'package:picturo_app/responses/my_profile_response.dart';
import 'package:picturo_app/responses/question_details_response.dart';
import 'package:picturo_app/responses/questions_response.dart';
import 'package:picturo_app/responses/topics_response.dart';
import 'package:picturo_app/responses/view_bank_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://picturoenglish.com/api/"; // Replace with your API URL
  static const String smsApiUrl = "http://site.ping4sms.com/api/";
  late SharedPreferences _prefs;
  late Dio _dio;

  static final ApiService _instance = ApiService._internal();

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15), // Set timeout
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        "Content-Type": "application/json",
        "accept": "*/*",
      },

    ));
  }
  

  static Future<ApiService> create() async {
    _instance._prefs = await SharedPreferences.getInstance();
    return _instance;
  }
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // or androidId or model based on need
  }
  Future<Map<String, dynamic>> login(
  String email, String password, BuildContext context) async {
  final String endpoint = "login.php"; // API endpoint

  // try {

  String? deviceId= await getDeviceId();
    Response response = await _dio.post(
      endpoint,
      data: jsonEncode({"email": email, "password": password,"device_id":deviceId}),
    );
// Debugging

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final Map<String, dynamic> data = response.data;

      // Check if the response contains both token and user_id
      if (!data.containsKey("token") || !data.containsKey("user_id")) {
        return {"error": "$data"};
      }

      // Save the token and user_id to SharedPreferences
      await _prefs.setString("auth_token", data["token"] ?? "");
      await _prefs.setString("user_id", data["user_id"]?.toString() ?? ""); // Ensure user_id is a string

      // Print the token and user_id to the console
      print("Token: ${data["token"]}");
      print("User ID: ${data["user_id"]}");

      return {
        "token": data["token"] ?? "",
        "userid": data["user_id"]?.toString() ?? "", // Ensure user_id is a string
        "success": true,
      };
    } else {
      return {"error": response.data["message"] ?? "Something went wrong"};
    }
  // } on DioException catch (e) {
  //   return {"error": e.response?.data["message"] ?? "Network error"};
  // }
}

  Future<bool> hitForOTP(String phoneNo) async {
    final random = Random();
    final sixDigitNumber = 1000 + random.nextInt(9000);

    String otp=sixDigitNumber.toString();
    String? mobileNum = phoneNo;
    // try {
    final uri = Uri.parse("http://site.ping4sms.com/api/smsapi?key=11ac642b5cd66a65bb0e636a0441619c&route=2&sender=MERSOF&number=$mobileNum&sms="
        "Your Login Verification code: $otp Don't share this code with others -MERCURY&templateid=1607100000000339284");
    var response = await http.post(
      uri,
    );


    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('otp_verify', otp);
      Fluttertoast.showToast(
        msg: "OTP Send SuccessFully",
      );
      return true;

    } else {
      Fluttertoast.showToast(
          msg: "OTP Send Failed",
          backgroundColor: Colors.red
      );
      return false;
    }
    // } catch (e) {
    //   emit(LoginFailure("Exception: ${e.toString()}"));
    // }
  }


Future<Map<String, dynamic>> signup(
  String username, String email, String mobile, String password, BuildContext context) async
{
  final String endpoint = "register.php"; // API endpoint

  try {
    Response response = await _dio.post(
      endpoint,
      data: jsonEncode({
        "username": username,
        "email": email,
        "mobile": mobile,
        "password": password
      }),
    );



    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final Map<String, dynamic> data = response.data;

      if (data["status"] == "success") {
        // Handle successful signup
        return {
          "status": data["status"],
          "message": data["message"],
          "referral_code": data["referral_code"],
          "token":data["token"],
          "user_id":data["user_id"],
          "success": true,
        };
      } else if (data["status"] == "error") {
        // Handle error response
        return {
          "error": data["message"] ?? "Invalid input data.",
          "success": false,
        };
      } else {
        // Handle unexpected response
        return {"error": "Unexpected response from the server.", "success": false};
      }
    } else {
      // Handle non-200 status code
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {
    // Handle network or server errors
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}
Future<Map<String, dynamic>> setPersonalDetails(
  String gender, String age, String speakingLevel, String location, String reason,String speakingLanguage,String qualification, BuildContext context) async {
  final String endpoint = "gender.php"; // API endpoint

  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Make the POST request with the Bearer token
    print("sdjcnslkdcsldc ${{
      "gender": gender,
      "age": age,
      "speaking_level": speakingLevel,
      "location": location,
      "reason": reason,
      "speaking_language":speakingLanguage,
      "qualification":qualification
    }}");
    Response response = await _dio.post(
      endpoint,
      data: jsonEncode({
        "gender": gender,
        "age": age,
        "speaking_level": speakingLevel,
        "location": location,
        "reason": reason,
        "speaking_language":speakingLanguage,
        "qualification":qualification
      }),
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token to the headers
        },
      ),
    );

    print("Raw API Response Personal Detailssss : ${response.data}"); // Debugging

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      final Map<String, dynamic> data = response.data;


      if (data["status"] == true) {
        // Handle successful update
        if(data['message'].toString().contains("updated successfully")){
          return {
            "status": data["status"],
            "message": data["message"],
            "success": true,
          };
        }else{
          return {
            "error": data["message"] ?? "Invalid input data.",
            "success": false,
          };
        }

      } else {
        // Handle error response
        return {
          "error": data["message"] ?? "Invalid input data.",
          "success": false,
        };
      }

    } else {
      // Handle non-200 status code
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {

    // Handle network or server errors
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}
Future<bool> setUserNativeLanguage(String language)async{
  String? token = await getAuthToken();

  // Send POST request to update the language
  final response = await _dio.post(
    "update_language.php",
    options:Options(headers:  {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"}),
    data:json.encode(
        {"speaking_language": language.toLowerCase()}),
  );

  if (response.statusCode == 200) {
    Fluttertoast.showToast(msg: "Language updated successfully");
    print('Language updated successfully: ${response.data}');
    return true;
  } else {
    Fluttertoast.showToast(msg: "Failed to update language",backgroundColor: Colors.red);
    print('Failed to update language: ${response.statusCode}');
    return false;
  }

}
  Future<bool> removeBankAccount(String accountNumber) async {
    String? token = await getAuthToken(); // Optional if API requires token

    try {
      final response = await _dio.post(
        "remove_account.php",
        options: Options(
          headers: {
            "Authorization": "Bearer $token", // Remove this line if not required
            "Content-Type": "application/json",
          },
        ),
        data: json.encode({
          "account_number": accountNumber,
        }),
      );

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "Account removed successfully",backgroundColor: Colors.green);
        print('Account removed successfully: ${response.data}');
        return true;
      } else {
        Fluttertoast.showToast(msg: "Failed to remove account", backgroundColor: Colors.red);
        print('Failed to remove account: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error removing account", backgroundColor: Colors.red);
      print('Error: $e');
      return false;
    }
  }


Future<Map<String, dynamic>> postBankAccount({
  required String accountNumber,
  required String confrimAccountNumber,
  required String accountHolderName,
  required String ifscCode,
}) async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Create the request body
    Map<String, dynamic> params = {
      "account_number": accountNumber,
      "confirm_account_number": confrimAccountNumber,
      "account_holder_name": accountHolderName,
      "ifsc_code": ifscCode,
    };

    // Make the POST request
    Response response = await _dio.post(
      "bankaccount.php",  // Replace with your actual API endpoint
      data: jsonEncode(params),
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}
Future<ViewBankAccountResponse> fetchBankAccount({
  required String userId,
}) async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request (since you're using queryParameters)
    Response response = await _dio.get(
      "bankdetails.php",  // Your API endpoint
      queryParameters: {"user_id": userId},
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200) {
      // Parse the response into your model
      return ViewBankAccountResponse.fromJson(response.data);
    } else {
      throw Exception(response.data["message"] ?? "Failed to fetch bank details");
    }
  } on DioException catch (e) {
    throw Exception(e.response?.data["message"] ?? "Network error: ${e.message}");
  } catch (e) {
    throw Exception("Unexpected error: $e");
  }
}


  /// 📌 **Method to Get Token for Future Requests**
  Future<String?> getAuthToken() async {
    return _prefs.getString("auth_token");
  }

  /// 📌 **Method to Call Authenticated API**
  Future<Response> getData(String endpoint) async {
    String? token = await getAuthToken();

    try {
      Response response = await _dio.get(
        endpoint,
        options: Options(headers: {
          "Authorization": "Bearer $token",
        }),
      );
      return response;
    } on DioException catch (e) {
      throw Exception("API Error: ${e.response?.data}");
    }
  }
 Future<LanguageResponse> fetchLanguages() async {
  final String endpoint = "get_languages.php"; // Replace with your actual endpoint

  try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return LanguageResponse.fromJson(response.data);
    } else {
      throw Exception("Failed to fetch languages: ${response.statusMessage}");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching languages: ${e.message}");
  }
}
Future<BookResponse> fetchBooks() async {
  final String endpoint = "books.php"; // Replace with your actual endpoint

  try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Validate the response data
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the required keys exist
        if (responseData.containsKey("status") && responseData.containsKey("data")) {
          return BookResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch books: ${response.statusMessage}");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching books: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("An unexpected error occurred: $e");
  }
}
Future<GamesResponse> fetchGames() async {
  final String endpoint = "games.php"; // Replace with your actual endpoint

  try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response

    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Validate the response data
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the required keys exist
        if (responseData.containsKey("status") && responseData.containsKey("data")) {
          return GamesResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch books: ${response.statusMessage}");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching books: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("An unexpected error occurred: $e");
  }
}
Future<UsersResponse> fetchAllUsers() async {
  final String endpoint = "allusers.php"; // Replace with your actual endpoint

  // try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Validate the response data
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the required keys exist
        if (responseData.containsKey("status") && responseData.containsKey("data")) {
          return UsersResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch books: ${response.statusMessage}");
    }


  // } on DioException catch (e) {
  //   print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
  //   throw Exception("Error fetching books: ${e.message}");
  // } catch (e) {
  //   print("Unexpected Error: $e");
  //   throw Exception("An unexpected error occurred: $e");
  // }
}
Future<FriendsResponse> fetchFriends() async {
  final String endpoint = "friends_list.php"; // Replace with your actual endpoint

  // try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response

    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Validate the response data
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the required keys exist
        if (responseData.containsKey("status") && responseData.containsKey("friends")) {
          return FriendsResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch books: ${response.statusMessage}");
    }

  // } on DioException catch (e) {
  //   print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
  //   throw Exception("Error fetching books: ${e.message}");
  // } catch (e) {
  //   print("Unexpected Error: $e");
  //   throw Exception("An unexpected error occurred: $e");
  // }
}
Future<RequestsResponse> fetchRequests() async {
  final String endpoint = "chat_request_list.php"; // Replace with your actual endpoint

  // try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Validate the response data
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the required keys exist
        if (responseData.containsKey("status") && responseData.containsKey("received_requests")) {
          return RequestsResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch books: ${response.statusMessage}");
    }
  // } on DioException catch (e) {
  //   print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
  //   throw Exception("Error fetching books: ${e.message}");
  // } catch (e) {
  //   print("Unexpected Error: $e");
  //   throw Exception("An unexpected error occurred: $e");
  // }
}
Future<TopicsResponse> fetchTopics(int bookId) async {
  final String endpoint = "topics.php"; // Replace with your actual endpoint

  try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token and book_id as a query parameter
    Response response = await _dio.get(
      endpoint,
      queryParameters: {
        'book_id': bookId, // Add book_id as a query parameter
      },
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );
    dev.log("sdkjlclksdcmsd ${response.data}");
    // Debugging: Print the raw API response


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Validate the response data
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the required keys exist
        if (responseData.containsKey("status") && responseData.containsKey("topics")) {
          return TopicsResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch topics: ${response.statusMessage}");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching topics: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("An unexpected error occurred: $e");
  }
}
Future<QuestionsResponse> fetchQuestions(int topicId) async {
  final String endpoint = "question.php"; 

  try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }



    Response response = await _dio.get(
      endpoint,
      queryParameters: {
        'topic_id': topicId, // Add book_id as a query parameter
      },
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    if (response.statusCode == 200) {


      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;


        if (responseData["status"] == "success"
        && responseData.containsKey("questions")) {
          return QuestionsResponse.fromJson(responseData);
        } else if(responseData["status"] == "error") {
          return QuestionsResponse.fromJson(responseData);
        }
        else  {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch topics: ${response.statusMessage}");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching topics: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("An unexpected error occurred: $e");
  }
}

Future<QuestionDetailsResponse> fetchDetailedQuestion(int questionId) async {
  final String endpoint = "example.php"; // Replace with your actual endpoint

  print('Passed questionId: $questionId'); // Debugging

  // try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token and question_id as a query parameter
    Response response = await _dio.post(
      endpoint,
      data: {
        'question_id': questionId,
      },
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response
  // dev.log("Raw API Response Eacch Questionssssssss: ${response.data}");

    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      // Validate the response data
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the required keys exist for a single question response
        if (responseData["status"] == "success" && 
            responseData.containsKey("question") &&
            responseData.containsKey("examples")) {
          return QuestionDetailsResponse.fromJson(responseData);
        } 
        else if(responseData["status"] == "error") {
          return QuestionDetailsResponse.fromJson(responseData);
        }
        else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch question: ${response.statusMessage}");
    }
  // } on DioException catch (e) {
  //   print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
  //   throw Exception("Error fetching question: ${e.message}");
  // } catch (e) {
  //   print("Unexpected Error: $e");
  //   throw Exception("An unexpected error occurred: $e");
  // }
}

Future<AvatarResponse> fetchAvatars() async {
  final String endpoint = "get-avatars.php"; 

  try {
    String? token = await getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );



    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return AvatarResponse.fromJson(response.data);
    } else {
      throw Exception("Invalid API response format.");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching avatars: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("An unexpected error occurred: $e");
  }
}
Future<bool?> readMarkAsRead({required String bookId,required String topicId,required String questionId}) async {
  final String endpoint = "mark_read.php";

  try {
    String? token = await getAuthToken();
    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    Response response = await _dio.post(
      endpoint,
      data: {
        "book_id": bookId,
        "topic_id": topicId,
        "question_id": questionId
      }
      ,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return true;
    } else {

    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching avatars: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("An unexpected error occurred: $e");
  }
  return null;
}

Future<UserResponse> fetchProfileDetails() async {
  final String endpoint = "users.php"; // Replace with your actual endpoint

  // try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the response has required user details
        if (responseData.containsKey("id") &&
            responseData.containsKey("username") &&
            responseData.containsKey("email")) {
          return UserResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch user details: ${response.statusMessage}");
    }
  // } on DioException catch (e) {
  //   print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
  //   throw Exception("Error fetching user details: ${e.message}");
  // } catch (e) {
  //   print("Unexpected Error: $e");
  //   throw Exception("An unexpected error occurred: $e");
  // }
}
Future<UserResponse> fetchUserProfileDetails(String token) async {
  final String endpoint = "users.php"; // Replace with your actual endpoint

  try {

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the GET request with the auth token
    Response response = await _dio.get(
      endpoint,
      options: Options(headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      }),
    );

    // Debugging: Print the raw API response


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Ensure the response has required user details
        if (responseData.containsKey("id") &&
            responseData.containsKey("username") &&
            responseData.containsKey("email")) {
          return UserResponse.fromJson(responseData);
        } else {
          throw Exception("Invalid API response: Missing required fields.");
        }
      } else {
        throw Exception("Invalid API response: Expected a JSON object.");
      }
    } else {
      throw Exception("Failed to fetch user details: ${response.statusMessage}");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Error fetching user details: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("An unexpected error occurred: $e");
  }
}

Future<Map<String, dynamic>> sendChatRequest({
  required int receiverId,
}) async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Create the request body
    Map<String, dynamic> params = {
      "receiver_id": receiverId,
    };

    // Make the POST request
    Response response = await _dio.post(
      "chat_request.php",  // Replace with your actual API endpoint
      data: jsonEncode(params),
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}

Future<Map<String, dynamic>> sendWithdrawalRequest({
  required String amount,
  required String paymentMethod
}) async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

     if (token == null || token.isEmpty) {
      return {
        "success": false,
        "error": "Authorization token is missing. Please log in.",
      };
    }

    // Create the request body
    Map<String, dynamic> params = {
      "amount": amount,
      "payment_method":paymentMethod
    };

    // Make the POST request
    Response response = await _dio.post(
      "send_withdraw_request.php", 
      data: jsonEncode(params),
      options: Options(
        headers: {
          "Authorization": "Bearer $token", 
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); 

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}
Future<Map<String, dynamic>> updateAvatar({
  required String userId,
  required int avatarId,
}) async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Create the request body
    Map<String, dynamic> params = {
      "user_id": userId,
      "avatar_id": avatarId
    };

    // Make the POST request
    Response response = await _dio.post(
      "update-avatar.php",  // Replace with your actual API endpoint
      data: jsonEncode(params),
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200 && response.data['status'] == 'success') {
      // Return the entire response data or a properly formatted map
      return {
        "success": true,
        "message": response.data['message'] ?? "Avatar updated successfully",
        "data": response.data // Include the entire response if needed
      };
    } else {
      return {
        "error": response.data["message"] ?? "Something went wrong", 
        "success": false
      };
    }
  } on DioException catch (e) {
    return {
      "error": e.response?.data["message"] ?? "Network error", 
      "success": false
    };
  }
}

Future<Map<String, dynamic>> updateProfile({
  String? username,
  String? email,
  String? mobile,
}) async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Create the request body
    Map<String, dynamic> params = {
      "username": username,
      "email": email,
      "mobile": mobile
    };

    // Make the POST request
    Response response = await _dio.post(
      "edit_profile.php",  // Replace with your actual API endpoint
      data: jsonEncode(params),
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200 && response.data['status'] == 'success') {
      // Return the entire response data or a properly formatted map
      return {
        "success": true,
        "message": response.data['message'] ?? "Avatar updated successfully",
        "data": response.data // Include the entire response if needed
      };
    } else {
      return {
        "error": response.data["message"] ?? "Something went wrong", 
        "success": false
      };
    }
  } on DioException catch (e) {
    return {
      "error": e.response?.data["message"] ?? "Network error", 
      "success": false
    };
  }
}

Future<Map<String, dynamic>> sendVerificationCode(
  String email, BuildContext context) async {
  final String endpoint = "forgot_password.php"; // API endpoint for sending verification code

  // try {
    Response response = await _dio.post(
      endpoint,
      data: jsonEncode({"email": email}),
    );
    print("sdljcnsjncslcnlsdkcmsdc ${response.data}");
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data;
        
        // Check if the verification code was sent successfully
        if (data["status"] == "success") {
          return {
            "status": "success",
            "message": data["message"] ?? "Verification code sent to your email."
          };
        } else {
          return {"error": data["message"] ?? "Failed to send verification code"};
        }
      } else {
        return {"error": "Invalid response format"};
      }
    } else {
      return {"error": response.data["message"] ?? "Something went wrong"};
    }
  // } on DioException catch (e) {
  //   return {"error": e.response?.data["message"] ?? "Network error"};
  // }
}

Future<Map<String, dynamic>> verifyVerificationCode(
  String email,String code, BuildContext context) async {
  final String endpoint = "verify_code.php"; // API endpoint for sending verification code

  try {
    Response response = await _dio.post(
      endpoint,
      data: jsonEncode({"email": email,"code":code}),
    );



    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data;
        
        // Check if the verification code was sent successfully
        if (data["status"] == "success") {
          return {
            "status": "success",
            "message": data["message"] ?? "Verification successful!."
          };
        } else if(data["status"] == "error") {
          return {"error": data["message"] ?? "Invalid or expired code."};
        }
      } else {
        return {"error": "Invalid response format"};
      }
    } else {
      return {"error": response.data["message"] ?? "Something went wrong"};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error"};
  }
  // Ensure a return or throw statement at the end
  return {"error": "Unexpected error occurred"};
}

Future<Map<String, dynamic>> changePasswordCode(
  String email,String code, BuildContext context) async {
  final String endpoint = "reset_password.php"; // API endpoint for sending verification code

  try {
    String? token = await getAuthToken();
    print("lsdkclksmccd ${{
      "email": email,
      "new_password": code
    }}");
    Response response = await _dio.post(
      endpoint,
      data: {
        "email": email,
        "new_password": code
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );
    print("sdlkcmslkdmcslkdcmsdlck ${response.data}");
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data;
        
        // Check if the verification code was sent successfully
        if (data["status"] == "success") {
          return {
            "status": "success",
            "message": data["message"] ?? "Password updated successfully."
          };
        } else if(data["status"] == "error") {
          return {"error": data["message"] ?? "Can't update the password.try again"};
        }
      } else {
        return {"error": "Invalid response format"};
      }
    } else {
      return {"error": response.data["message"] ?? "Something went wrong"};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error"};
  }
  // Ensure a return or throw statement at the end
  return {"error": "Unexpected error occurred"};
}

Future<Map<String, dynamic>> acceptChatRequest({
  required int requestId,
}) async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Create the request body
    Map<String, dynamic> params = {
      "request_id": requestId,
    };

    // Make the POST request
    Response response = await _dio.post(
      "accept_chat_request.php",  // Replace with your actual API endpoint
      data: jsonEncode(params),
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}

Future<Map<String, dynamic>> deleteAccount() async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Make the POST request
    Response response = await _dio.post(
      "account_delete.php",  // Replace with your actual API endpoint
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200  && response.data['success'] ==true && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}

Future<Map<String, dynamic>> logoutAccount() async {
  try {
    // Retrieve the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      return {"error": "Authorization token is missing. Please log in.", "success": false};
    }

    // Make the POST request
    Response response = await _dio.post(
      "logout.php",  // Replace with your actual API endpoint
      options: Options(
        headers: {
          "Authorization": "Bearer $token", // Add the Bearer token
          "Content-Type": "application/json",
        },
      ),
    );

    print("API Response: ${response.data}"); // Debugging

    if (response.statusCode == 200  && response.data['success'] ==true && response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      return {"error": response.data["message"] ?? "Something went wrong", "success": false};
    }
  } on DioException catch (e) {
    return {"error": e.response?.data["message"] ?? "Network error", "success": false};
  }
}


Future<MessagesResponse> fetchMessages({required int receiverId}) async {
  final String endpoint = "chathistory.php"; // Replace with your actual endpoint

  try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the POST request with receiver_id in the body
    Response response = await _dio.post(
      endpoint,
      data: {
        'receiver_id': receiverId, // Include receiver_id in request body
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ),
    );


    // Debugging: Print the raw API response


    // log("Raw API 999999999999 Response: ${response.data}");


    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Validate response structure
        if (responseData.containsKey("status") &&
            responseData.containsKey("messages")) {
          
          // Validate each message contains required fields
          final messages = responseData['messages'] as List;
          for (var msg in messages) {
            if (!msg.containsKey('receiver_id') || 
                !msg.containsKey('sender_id') ||
                !msg.containsKey('message')) {
              throw Exception("Invalid message format: missing required fields");
            }
          }
          
          return MessagesResponse.fromJson(responseData);
        } else {
          throw Exception("API response missing required fields");
        }
      } else {
        throw Exception("Invalid API response format");
      }
    } else {
      throw Exception("Failed to fetch messages: ${response.statusMessage}");
    }
  } on DioException catch (e) {
    print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
    throw Exception("Network error: ${e.message}");
  } catch (e) {
    print("Unexpected Error: $e");
    throw Exception("Failed to load messages");
  }
}
Future<bool?> sendMessagesToAPI({required Map<String,dynamic> messageMap}) async {
  final String endpoint = "chat.php"; // Replace with your actual endpoint

  // try {
    // Fetch the saved auth token
    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    // Make the POST request with receiver_id in the body
  print("sdlkcslkdcmsdc ${messageMap}");
    Response response = await _dio.post(
      "http://picturoenglish.com/api/chat.php",
      data: json.encode(messageMap),
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ),
    );


    // Debugging: Print the raw API response
    print("Send API -- Response: ${response.data}");

    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      if (response.data is Map<String, dynamic>) {
        Map<String, dynamic> responseData = response.data;

        // Validate response structure
        if (responseData.containsKey("status")) {

          return true;
        } else {

        }
      } else {

      }
    } else {

    }
    return null;
  // } on DioException catch (e) {
  //   print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
  //   throw Exception("Network error: ${e.message}");
  // } catch (e) {
  //   print("Unexpected Error: $e");
  //   throw Exception("Failed to load messages");
  // }
}


  Future<Map<String, dynamic>> sendSms({
    required String phoneNumber,
    required String message,
  }) async
  {
    try {
      final Map<String, dynamic> body = {
        "key": "11ac642b5cd66a65bb0e636a0441619c", 
        "route": "2", 
        "sender": "MERSOF",
        "number": phoneNumber,
        "sms": "Your Login Verification code:$message Don't share this code with others -MERCURY",
        "templateid": '1607100000000339284',
      };

      
      Response response = await _dio.post(
        smsApiUrl,
        data: body,
        options: Options(
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
        ),
      );

      
      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": "SMS sent successfully",
          "data": response.data,
        };
      } else {
        return {
          "success": false,
          "error": "Failed to send SMS: ${response.statusMessage}",
        };
      }
    } on DioException catch (e) {
      return {
        "success": false,
        "error": "Error sending SMS: ${e.message}",
      };
    }
  }


  Future<Map<String, dynamic>> blockUser(
      int userId) async
  {
    final String endpoint = "blocked.php"; // API endpoint

    String? token = await getAuthToken();

    if (token == null || token.isEmpty) {
      throw Exception("Authorization token is missing. Please log in.");
    }

    try {
      print("inside block api");
      Response response = await _dio.post(
        endpoint,
        data: jsonEncode({
          "user_id":userId
        }),
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );



      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = response.data;

        if (data["status"] == "success") {
          // Handle successful signup
          return {
            "status": data["status"],
            "message": data["message"],
            "referral_code": data["referral_code"],
            "token":data["token"],
            "user_id":data["user_id"],
            "success": true,
          };
        } else if (data["status"] == "error") {
          // Handle error response
          return {
            "error": data["message"] ?? "Invalid input data.",
            "success": false,
          };
        } else {
          // Handle unexpected response
          return {"error": "Unexpected response from the server.", "success": false};
        }
      } else {
        // Handle non-200 status code
        return {"error": response.data["message"] ?? "Something went wrong", "success": false};
      }
    } on DioException catch (e) {
      // Handle network or server errors
      return {"error": e.response?.data["message"] ?? "Network error", "success": false};
    }
  }


  Future<List> getBlockedUsers(int userId) async {
    final String endpoint = "blocked_user_list.php?user_id=$userId"; // Replace with your actual endpoint

    try {
      // Fetch the saved auth token
      String? token = await getAuthToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authorization token is missing. Please log in.");
      }

      // Make the GET request with the auth token
      Response response = await _dio.get(
        endpoint,
        options: Options(headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        }),
      );



      // Check if the response status code is 200 (OK)
      if (response.statusCode == 200) {
        // Validate the response data
        if (response.data is Map<String, dynamic>) {
          Map<String, dynamic> responseData = response.data;

          // Ensure the required keys exist
          if (responseData.containsKey("status") && responseData.containsKey("data")) {

            print("responseData");
            print(json.encode(responseData));

            return (responseData["data"]);
          } else {
            throw Exception("Invalid API response: Missing required fields.");
          }
        } else {
          throw Exception("Invalid API response: Expected a JSON object.");
        }
      } else {
        throw Exception("Failed to fetch books: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
      throw Exception("Error fetching books: ${e.message}");
    } catch (e) {
      print("Unexpected Error: $e");
      throw Exception("An unexpected error occurred: $e");
    }
  }
  Future<void> unblockUser(int userId) async {
    String? token = await getAuthToken();

    final response = await _dio.post(
      'unblock_user.php',
      data: {'user_id': userId},
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
          'Content-Type': 'application/json',
        },
      ),
    );
    print("sldjkcslkcsdc ${response.data}");
    if(response.statusCode == 200){
      Map<String, dynamic> responseData = response.data;
      if(responseData['status']){
        Fluttertoast.showToast(msg: '${responseData['message']}',backgroundColor: Colors.green);
      }else{
        Fluttertoast.showToast(msg: '${responseData['message']}',backgroundColor: Colors.red);
      }
    }else if (response.statusCode != 200) {
      Fluttertoast.showToast(msg: 'Unable to Unblock Check Your Internet Connection',backgroundColor: Colors.red);
      throw Exception('Failed to unblock user');
    }
  }

}
