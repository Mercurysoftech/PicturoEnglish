part of 'faq_details_cubit.dart';

abstract class FAQState extends Equatable {
  const FAQState();

  @override
  List<Object?> get props => [];
}

class FAQInitial extends FAQState {}

class FAQLoading extends FAQState {}

class FAQLoaded extends FAQState {
  final List<FAQ> faqs;

  const FAQLoaded(this.faqs);

  @override
  List<Object?> get props => [faqs];
}

class FAQError extends FAQState {
  final String message;

  const FAQError(this.message);

  @override
  List<Object?> get props => [message];
}
class FAQ {
  final String question;
  final String answer;

  FAQ({required this.question, required this.answer});

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}