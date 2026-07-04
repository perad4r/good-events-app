import 'package:sukientotapp/data/models/partner/service_area_model.dart';

abstract class PartnerServiceAreaRepository {
  Future<PartnerServiceAreasResponse> getServiceAreas({
    int page = 1,
    int perPage = 50,
  });

  Future<PartnerServiceAreasResponse> addServiceAreas(
    List<int> locationIds, {
    int page = 1,
    int perPage = 50,
  });

  Future<PartnerServiceAreasResponse> updateServiceAreas(
    List<int> locationIds, {
    int page = 1,
    int perPage = 50,
  });
}
