# Generated by Django 2.0.3 on 2018-03-21 08:24

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('flow_rpt', '0007_remove_stage_comment'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='flow',
            options={'ordering': ['-created_time']},
        ),
    ]