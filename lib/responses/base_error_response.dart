abstract class BaseResponse {
  final String status;
  final String? message;

  BaseResponse({required this.status, this.message});

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
}