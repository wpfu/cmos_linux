# Generated by Django 2.0 on 2017-12-04 02:59

import django.contrib.postgres.fields.jsonb
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Block',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=20)),
                ('data', django.contrib.postgres.fields.jsonb.JSONField(blank=True, default=dict)),
            ],
        ),
        migrations.CreateModel(
            name='Proj',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=20, unique=True)),
                ('data', django.contrib.postgres.fields.jsonb.JSONField(blank=True, default=dict)),
            ],
        ),
        migrations.CreateModel(
            name='Title',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('proj', django.contrib.postgres.fields.jsonb.JSONField(blank=True, default=list)),
                ('block', django.contrib.postgres.fields.jsonb.JSONField(blank=True, default=list)),
                ('version', django.contrib.postgres.fields.jsonb.JSONField(blank=True, default=list)),
            ],
        ),
        migrations.CreateModel(
            name='User',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=20, unique=True)),
                ('data', django.contrib.postgres.fields.jsonb.JSONField(blank=True, default=dict)),
            ],
        ),
        migrations.CreateModel(
            name='Version',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=50)),
                ('data', django.contrib.postgres.fields.jsonb.JSONField(blank=True, default=dict)),
                ('block', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='be_rpt.Block')),
                ('owner', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='be_rpt.User')),
            ],
        ),
        migrations.AddField(
            model_name='proj',
            name='owner',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='be_rpt.User'),
        ),
        migrations.AddField(
            model_name='block',
            name='owner',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, to='be_rpt.User'),
        ),
        migrations.AddField(
            model_name='block',
            name='proj',
            field=models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='be_rpt.Proj'),
        ),
        migrations.AlterUniqueTogether(
            name='version',
            unique_together={('name', 'block')},
        ),
        migrations.AlterUniqueTogether(
            name='block',
            unique_together={('name', 'proj')},
        ),
    ]