# Generated by Django 2.0 on 2017-12-04 05:13

from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('be_rpt', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='version',
            name='created_time',
            field=models.DateTimeField(auto_now_add=True, default=django.utils.timezone.now),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='version',
            name='owner',
            field=models.ForeignKey(default=2, on_delete=django.db.models.deletion.CASCADE, to='be_rpt.User'),
            preserve_default=False,
        ),
        migrations.AlterUniqueTogether(
            name='version',
            unique_together=set(),
        ),
    ]