import 'package:flutter_test/flutter_test.dart';
import 'package:trulura/models/experience/experience_mode.dart';
import 'package:trulura/models/user.dart';
import 'package:trulura/models/post.dart';
import 'package:trulura/services/visibility_service.dart';
void main() {
  for (final privacy in ['followers','friends','private','unknown','', 'public']) {
    test('non-owner privacy handling: $privacy', () {
      final now = DateTime.now();
      final post = Post(id:'post',userId:'author',content:'test',type:'text',privacy:privacy,category:'ForYou',experienceMode:TruExperienceMode.social,createdAt:now,updatedAt:now);
      final permissions = TruExperienceMode.social.basePermissions();
      final ctx = TruParticipationContext(activeMode:TruExperienceMode.social,passiveModes:[],restrictedModes:[],activePermissions:permissions,effectivePermissions:permissions);
      for (final viewer in <User?>[null,User.fromJson({'id':'other','age':25})]) {
        expect(const VisibilityService().canViewPost(post:post,ctx:ctx,viewer:viewer).allowed, privacy == 'public');
      }
      final author = User.fromJson({'id':'author','age':25});
      expect(const VisibilityService().canViewPost(post:post,ctx:ctx,viewer:author).allowed,isTrue);
    });
  }
}