import 'package:sukientotapp/core/utils/logger.dart';
import 'package:sukientotapp/data/models/partner/service_area_model.dart';
import 'package:sukientotapp/data/providers/partner/service_area_provider.dart';
import 'package:sukientotapp/domain/repositories/partner/service_area_repository.dart';

class PartnerServiceAreaRepositoryImpl implements PartnerServiceAreaRepository {
  final PartnerServiceAreaProvider _provider;

  PartnerServiceAreaRepositoryImpl(this._provider);

  @override
  Future<PartnerServiceAreasResponse> getServiceAreas() async {
    try {
      final raw = await _provider.getServiceAreas();
      return PartnerServiceAreasResponse.fromJson(raw);
    } catch (e) {
      logger.e('[PartnerServiceAreaRepositoryImpl] [getServiceAreas] $e');
      rethrow;
    }
  }

  @override
  Future<PartnerServiceAreasResponse> addServiceAreas(
    List<int> locationIds,
  ) async {
    try {
      final raw = await _provider.addServiceAreas(locationIds);
      return PartnerServiceAreasResponse.fromJson(raw);
    } catch (e) {
      logger.e('[PartnerServiceAreaRepositoryImpl] [addServiceAreas] $e');
      rethrow;
    }
  }

  @override
  Future<PartnerServiceAreasResponse> updateServiceAreas(
    List<int> locationIds,
  ) async {
    try {
      final raw = await _provider.updateServiceAreas(locationIds);
      return PartnerServiceAreasResponse.fromJson(raw);
    } catch (e) {
      logger.e('[PartnerServiceAreaRepositoryImpl] [updateServiceAreas] $e');
      rethrow;
    }
  }
}
