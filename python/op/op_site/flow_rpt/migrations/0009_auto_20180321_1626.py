# Generated by Django 2.0.3 on 2018-03-21 08:26

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('flow_rpt', '0008_auto_20180321_1624'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='stage',
            options={'ordering': ['-created_time']},
        ),
    ]
