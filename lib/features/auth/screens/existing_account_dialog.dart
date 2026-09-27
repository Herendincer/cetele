import 'package:flutter/material.dart';

Future<bool> confirmExistingAccount(BuildContext context) async {
  if (!context.mounted) return false;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bu Google hesabı zaten kayıtlı'),
          content: const SingleChildScrollView(
            child: Text(
              'Bu Google hesabına bağlı mevcut bir Çetele hesabınız var. '
              'Devam ederseniz o hesaba giriş yapılacak. '
              'Bu cihazda misafir olarak oluşturduğunuz veriler, özellikle henüz '
              'eşitlenmemiş olanlar, mevcut hesabınızla birleştirilmeyecek. '
              'Misafir hesabınızdaki verilere o hesaptan erişemeyeceksiniz. '
              'Devam etmek istiyor musunuz?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Mevcut hesaba giriş yap'),
            ),
          ],
        ),
      ) ??
      false;
}
