# -*- coding: utf-8 -*-
# Generated by Django 1.11.1 on 2017-05-11 09:32
from __future__ import unicode_literals

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Auth',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=10, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='Dir',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=1000)),
                ('date', models.DateTimeField(auto_now=True)),
                ('auth', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='user_info.Auth')),
            ],
        ),
        migrations.CreateModel(
            name='Group',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(blank=True, max_length=100, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='Level',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=20, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='Proj',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=20, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='Repos',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=20, unique=True)),
            ],
        ),
        migrations.CreateModel(
            name='User',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=20)),
                ('date', models.DateTimeField(auto_now=True)),
                ('group', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='user_info.Group')),
                ('level', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='user_info.Level')),
                ('proj', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='user_info.Proj')),
                ('repos', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='user_info.Repos')),
            ],
        ),
        migrations.AddField(
            model_name='dir',
            name='group',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='user_info.Group'),
        ),
        migrations.AddField(
            model_name='dir',
            name='level',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='user_info.Level'),
        ),
        migrations.AddField(
            model_name='dir',
            name='proj',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='user_info.Proj'),
        ),
        migrations.AddField(
            model_name='dir',
            name='repos',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='user_info.Repos'),
        ),
        migrations.AlterUniqueTogether(
            name='user',
            unique_together=set([('name', 'repos', 'proj', 'level', 'group')]),
        ),
        migrations.AlterUniqueTogether(
            name='dir',
            unique_together=set([('name', 'repos', 'proj', 'level', 'group')]),
        ),
    ]