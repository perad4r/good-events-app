import 'package:sukientotapp/data/models/partner/service_area_model.dart';

abstract class PartnerServiceAreaRepository {
  Future<PartnerServiceAreasResponse> getServiceAreas();
  Future<PartnerServiceAreasResponse> addServiceAreas(List<int> locationIds);
  Future<PartnerServiceAreasResponse> updateServiceAreas(List<int> locationIds);
}
