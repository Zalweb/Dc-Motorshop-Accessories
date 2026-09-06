/// Web-safe maintenance repository. The web build is cloud-only, so there is
/// no local Isar data to wipe; these are no-ops.
class MaintenanceRepositoryWeb {
  const MaintenanceRepositoryWeb();

  Future<void> resetLocalData() async {}

  Future<void> deleteAllLocal() async {}
}
