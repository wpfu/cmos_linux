# Generated by Django 2.0.3 on 2018-03-20 03:54

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('flow_rpt', '0005_auto_20180316_1933'),
    ]

    operations = [
        migrations.AddField(
            model_name='flow',
            name='comment',
            field=models.CharField(blank=True, max_length=200),
        ),
        migrations.AddField(
            model_name='stage',
            name='comment',
            field=models.CharField(blank=True, max_length=200),
        ),
    ]