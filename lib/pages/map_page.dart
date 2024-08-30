import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_project/providers/providers.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => MapPageState();
}

class MapPageState extends ConsumerState<MapPage> {
  @override
  Widget build(BuildContext context) {
    ref
        .watch(locationControllerProvider)
        .onLocationChanged
        .listen((location) async {
      if (location.latitude != null && location.longitude != null) {
        final currLocation = LatLng(location.latitude!, location.longitude!);

        final controller = ref.read(googleMapControllerProvider);
        if (controller != null) {
          final zoomLevel = await controller.getZoomLevel();
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currLocation,
              zoom: zoomLevel,
            ),
          ));
        }

        ref.watch(locationProvider.notifier).state = currLocation;
        if (ref.watch(isStartedProvider)) {
          final lastLocation = ref.watch(routeCoordsProvider).last;
          ref.watch(routeCoordsProvider.notifier).state.add(currLocation);
          final distance = Geolocator.distanceBetween(
            lastLocation.latitude,
            lastLocation.longitude,
            currLocation.latitude,
            currLocation.longitude,
          );
          ref
              .read(distanceProvider.notifier)
              .update((state) => state + distance);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Distance calculator'),
        actions: [
          Text('${(ref.watch(distanceProvider) / 1000).toStringAsFixed(2)} km'),
          const SizedBox(width: 16),
        ],
      ),
      body: ref.watch(getLocationPermissionProvider).when(
        data: (data) {
          if (data) {
            final location = ref.watch(locationProvider);
            if (location != null) {
              return GoogleMap(
                myLocationEnabled: true,
                compassEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: location,
                  zoom: 14,
                ),
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    visible: true,
                    points: ref.watch(routeCoordsProvider),
                    width: 4,
                    color: Colors.blue,
                    startCap: Cap.roundCap,
                    endCap: Cap.buttCap,
                  ),
                },
                onMapCreated: (controller) {
                  ref.read(googleMapControllerProvider.notifier).state =
                      controller;
                },
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          } else {
            return const Text('No permission');
          }
        },
        error: (error, st) {
          return const Text('some error occurred');
        },
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!ref.watch(isStartedProvider)) {
            final currLocation = ref.watch(locationProvider)!;
            ref.read(isStartedProvider.notifier).state = true;
            ref.read(routeCoordsProvider.notifier).state = [];
            ref.read(routeCoordsProvider.notifier).state.add(currLocation);
            ref.read(distanceProvider.notifier).state = 0.0;
          } else {
            ref.read(isStartedProvider.notifier).state = false;
          }
        },
        label: ref.watch(isStartedProvider)
            ? const Text('Stop')
            : const Text('Start'),
        icon: ref.watch(isStartedProvider)
            ? const Icon(Icons.close)
            : const Icon(Icons.start),
      ),
    );
  }
}
