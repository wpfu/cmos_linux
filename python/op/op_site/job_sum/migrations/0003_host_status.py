# Generated by Django 2.0.4 on 2018-06-04 06:05

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('job_sum', '0002_auto_20180530_1746'),
    ]

    operations = [
        migrations.AddField(
            model_name='host',
            name='status',
            field=models.BooleanField(default=True),
            preserve_default=False,
        ),
    ]