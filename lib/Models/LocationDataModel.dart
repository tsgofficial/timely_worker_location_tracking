// To parse this JSON data, do
//
//     final locationDataModel = locationDataModelFromJson(jsonString);

import 'dart:convert';

LocationDataModel locationDataModelFromJson(String str) =>
    LocationDataModel.fromJson(json.decode(str));

String locationDataModelToJson(LocationDataModel data) =>
    json.encode(data.toJson());

class LocationDataModel {
  LocationDataModel({
    this.success,
    this.message,
    this.data,
  });

  int? success;
  String? message;
  List<LocationList>? data;

  factory LocationDataModel.fromJson(Map<String, dynamic> json) =>
      LocationDataModel(
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? []
            : List<LocationList>.from(
                json["data"]!.map((x) => LocationList.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class LocationList {
  LocationList({
    this.id,
    this.longitude,
    this.latitude,
    this.date,
    this.userId,
    this.stayTime,
    this.createdAt,
  });

  int? id;
  String? longitude;
  String? latitude;
  DateTime? date;
  int? userId;
  int? stayTime;
  DateTime? createdAt;

  factory LocationList.fromJson(Map<String, dynamic> json) => LocationList(
        id: json["id"],
        longitude: json["longitude"],
        latitude: json["latitude"],
        date: json["date"] == null ? null : DateTime.parse(json["date"]),
        userId: json["user_id"],
        stayTime: json["stay_time"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "longitude": longitude,
        "latitude": latitude,
        "date":
            "${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}",
        "user_id": userId,
        "stay_time": stayTime,
        "created_at": createdAt?.toIso8601String(),
      };
}
