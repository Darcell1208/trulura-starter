import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/services/visibility_service.dart';
void main() {
  for (final mode in [TruExperienceMode.dating, TruExperienceMode.luxe, TruExperienceMode.altIntimate]) {
    for (final age in <int?>[null,0,17,18]) {
      test('$mode denies missing, underage or unverified viewer $age even for own post', () {
        final viewer = age == null ? null : User.fromJson({'id':'author','age':age});
        final now = DateTime.now();
        final post = Post(id:'post',userId:'author',content:'test',type:'text',privacy:'public',category:'ForYou',experienceMode:mode,createdAt:now,updatedAt:now);
        final permissions = mode.basePermissions();
        final ctx = TruParticipationContext(activeMode:mode,passiveModes:[],restrictedModes:[],activePermissions:permissions,effectivePermissions:permissions);
        expect(const VisibilityService().canViewPost(post:post,ctx:ctx,viewer:viewer).allowed,isFalse);
        final adult = User.fromJson({'id':'author','age':18}).copyWith(verificationLevel:TruVerificationLevel.level3);
        expect(const VisibilityService().canViewPost(post:post,ctx:ctx,viewer:adult).allowed,isTrue);
      });
    }
  }
}