## Автоматическая преднастроенная установка Astra Linux 1.8

Через Ventoy интегрируется `grub.cfg` и `preseed.cfg`. 

`grub.cfg` отвечает за то чтобы изменить пункты загрузчика Grub2, дает 5 секунд таймаута, а также прописывает соглашение с лицензцией.

`preseed.cfg` содержит ответы на вопросы установщика.

`preseed.cfg` перед завершение установки выполняет несколько инструкций: 
- Включает NTP из под systemd
- Очищает ethernet подключения
- Настраивает некоторые настройки клавиатуры
- Скачивает `postinstall.sh` и `postinstall_user.sh` скрипты
- Создает desktop файл (ярлык) в папке глобальной автозагрузки, который запускает `postinstall.sh`
- Создает `postinstall_download.sh`, для тех случаев если `postinstall.sh` и `postinstall_user.sh` не скачались в позапрошлом пункте, либо необходимо обновить эти скрипты
- Создает `connect_domain.sh`, он подключает ПК к домену и скрипт самоуничтожается

<hr>

Скрипты находятся `/usr/local/bin`, они автоматически прописаны в PATH, поэтому для их запуска не нужно прописывать весь путь.
Их можно запустить вручную:
- `sudo postinstall_download.sh` - скачать\обновить `postinstall.sh` и `postinstall_user.sh`
- `sudo postinstall.sh` - запуск постустановки системыных (требуются администраторские права и локальный аккаунт (аккаунт не в домене)) и пользовательских настроек 
- `sudo postinstall_user.sh` - запуск постустановки пользовательских настроек

<hr>

Создано в КАТ.

Если будете использовать под себя - обязательно просмотрите файлы и измените под свои нужды.
