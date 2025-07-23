/// top_actions : [{"action":"air drumming","count":6},{"action":"skydiving","count":3}]

class ActionSnapResultModel {
  ActionSnapResultModel({
      this.topActions,});

  ActionSnapResultModel.fromJson(dynamic json) {
    if (json['top_actions'] != null) {
      topActions = [];
      json['top_actions'].forEach((v) {
        topActions?.add(TopActions.fromJson(v));
      });
    }
  }
  List<TopActions>? topActions;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (topActions != null) {
      map['top_actions'] = topActions?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// action : "air drumming"
/// count : 6

class TopActions {
  TopActions({
      this.action, 
      this.count,});

  TopActions.fromJson(dynamic json) {
    action = json['action'];
    count = json['count'];
  }
  String? action;
  num? count;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['action'] = action;
    map['count'] = count;
    return map;
  }

}