# Generated by Django 2.0.4 on 2018-06-04 10:14

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('job_sum', '0003_host_status'),
    ]

    operations = [
        migrations.AddField(
            model_name='host',
            name='time',
            field=models.DateTimeField(auto_now=True),
        ),
    ]