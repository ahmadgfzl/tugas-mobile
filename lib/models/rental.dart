class Rental {
  final int id;
  final int motorcycleId;
  final int userId;
  final String startDate;
  final String endDate;
  final num totalPrice;
  final String status;
  final String? motorcycleBrand;
  final String? motorcycleModel;

  Rental({required this.id,required this.motorcycleId,required this.userId,required this.startDate,required this.endDate,required this.totalPrice,required this.status,this.motorcycleBrand,this.motorcycleModel});

  factory Rental.fromJson(Map<String,dynamic> j)=>Rental(
    id:_asInt(j['id']),
    motorcycleId:_asInt(j['motorcycle_id']),
    userId:_asInt(j['user_id']??0),
    startDate:j['start_date']??'',
    endDate:j['end_date']??'',
    totalPrice:_asNum(j['total_price']),
    status:j['status']??'',
    motorcycleBrand:j['brand'],
    motorcycleModel:j['model'],
  );
}

int _asInt(dynamic v){
  if(v is int) return v; if(v is num) return v.toInt(); if(v is String) return int.tryParse(v)??0; return 0;
}
num _asNum(dynamic v){
  if(v is num) return v; if(v is String) return num.tryParse(v)??0; return 0;
}
