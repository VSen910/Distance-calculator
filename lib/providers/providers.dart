import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

final locationControllerProvider = Provider<Location>((ref) => Location());

final googleMapControllerProvider = StateProvider<GoogleMapController?>((ref) => null);

final locationProvider = StateProvider<LatLng?>((ref) => null);

final routeCoordsProvider = StateProvider<List<LatLng>>((ref) => []);

final isStartedProvider = StateProvider<bool>((ref) => false);

final distanceProvider = StateProvider<double>((ref) => 0.0);

final getLocationPermissionProvider = FutureProvider((ref) async {
  final locationController = ref.watch(locationControllerProvider);
  bool serviceEnabled = await locationController.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await locationController.requestService();
    if(!serviceEnabled) {
      return false;
    }
  }

  PermissionStatus permissionStatus = await locationController.hasPermission();
  if (permissionStatus == PermissionStatus.denied) {
    permissionStatus = await locationController.requestPermission();
    if (permissionStatus != PermissionStatus.granted) {
      return false;
    }
  }

  return true;
});
