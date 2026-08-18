import 'package:ai_chat/data/models/chat_message.dart';
import 'package:ai_chat/data/models/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conversation 消息树', () {
    test('线性追加后 activePath 顺序正确', () {
      final c = Conversation();
      final m1 = ChatMessage(role: MessageRole.user, content: '你好');
      c.addMessage(m1);
      final m2 = ChatMessage(role: MessageRole.assistant, content: '你好呀');
      c.addMessage(m2, parentId: m1.id);

      final path = c.activePath;
      expect(path.length, 2);
      expect(path[0].content, '你好');
      expect(path[1].content, '你好呀');
    });

    test('重新生成产生兄弟分支，页码为 1/2 与 2/2', () {
      final c = Conversation();
      final user = ChatMessage(role: MessageRole.user, content: '讲个笑话');
      c.addMessage(user);

      final a1 = ChatMessage(role: MessageRole.assistant, content: '版本一');
      c.addMessage(a1, parentId: user.id);
      final a2 = ChatMessage(role: MessageRole.assistant, content: '版本二');
      c.addMessage(a2, parentId: user.id);

      // 新增的分支自动成为激活分支
      expect(c.activePath.last.content, '版本二');

      final info2 = c.branchInfoOf(a2.id);
      expect(info2.$1, 1);
      expect(info2.$2, 2);

      // 切回第一个分支
      c.switchBranch(a1.id);
      expect(c.activePath.last.content, '版本一');

      final info1 = c.branchInfoOf(a1.id);
      expect(info1.$1, 0);
      expect(info1.$2, 2);
    });

    test('编辑用户消息形成并列分支，各自子树独立', () {
      final c = Conversation();
      final u1 = ChatMessage(role: MessageRole.user, content: '原始提问');
      c.addMessage(u1);
      final r1 = ChatMessage(role: MessageRole.assistant, content: '原始回答');
      c.addMessage(r1, parentId: u1.id);

      // 编辑：在根层新增一个兄弟
      final u2 = ChatMessage(role: MessageRole.user, content: '修改后的提问');
      c.addMessage(u2);
      final r2 = ChatMessage(role: MessageRole.assistant, content: '新的回答');
      c.addMessage(r2, parentId: u2.id);

      expect(
        c.activePath.map((m) => m.content).toList(),
        ['修改后的提问', '新的回答'],
      );

      c.switchBranch(u1.id);
      expect(c.activePath.map((m) => m.content).toList(), ['原始提问', '原始回答']);
    });

    test('删除子树会连带移除后代', () {
      final c = Conversation();
      final u = ChatMessage(role: MessageRole.user, content: 'A');
      c.addMessage(u);
      final a = ChatMessage(role: MessageRole.assistant, content: 'B');
      c.addMessage(a, parentId: u.id);
      final u2 = ChatMessage(role: MessageRole.user, content: 'C');
      c.addMessage(u2, parentId: a.id);

      expect(c.messages.length, 3);
      c.deleteSubtree(a.id);
      expect(c.messages.length, 1);
      expect(c.activePath.single.content, 'A');
    });

    test('序列化往返保持树结构与激活分支', () {
      final c = Conversation(title: '测试对话');
      final u = ChatMessage(role: MessageRole.user, content: '问题');
      c.addMessage(u);
      final a1 = ChatMessage(role: MessageRole.assistant, content: '答案一');
      c.addMessage(a1, parentId: u.id);
      final a2 = ChatMessage(role: MessageRole.assistant, content: '答案二');
      c.addMessage(a2, parentId: u.id);
      c.switchBranch(a1.id);

      final restored = Conversation.fromJson(c.toJson());
      expect(restored.title, '测试对话');
      expect(restored.messages.length, 3);
      expect(restored.activePath.last.content, '答案一');

      final info = restored.branchInfoOf(a1.id);
      expect(info.$1, 0);
      expect(info.$2, 2);
    });
  });
}