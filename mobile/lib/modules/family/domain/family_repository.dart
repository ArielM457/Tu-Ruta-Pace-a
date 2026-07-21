import 'family_entities.dart';

abstract class FamilyRepository {
  Future<FamilyGroup?> getMyGroup();

  Future<FamilyGroup> createGroup(String name);

  Future<FamilyInvite> inviteMember({String? email, String? relationshipLabel});

  Future<FamilyGroup> acceptInvitation(String code);
}
