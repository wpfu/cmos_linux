from rest_framework import views
from rest_framework.response import Response
from rest_framework import status
from rest_framework import generics
from rest_framework import permissions
from .models import User, Title, Proj, Block, Flow, Stage
from .serializers import UserSerializer, TitleSerializer, ProjSerializer, BlockSerializer, FlowSerializer, StageSerializer
from .serializers import UserRelatedSerializer, ProjRelatedSerializer, BlockRelatedSerializer, FlowRelatedSerializer, StageDetailSerializer
from .serializers import FlowStatusSerializer, FlowStatusRelatedSerializer
from django.db.models import Q
from django.utils import timezone as tz
from django.conf import settings
import dateutil.parser
import pytz
import os
import shutil

class TitleList(generics.ListAPIView):
    """flow report title list"""
    queryset = Title.objects.all()
    serializer_class = TitleSerializer

class TitleDetail(generics.RetrieveAPIView):
    """flow report title detail"""
    queryset = Title.objects.all()
    serializer_class = TitleSerializer

class ProjList(generics.ListAPIView):
    """flow report project list"""
    queryset = Proj.objects.all()
    serializer_class = ProjSerializer
    def get_queryset(self, *args, **kwargs):
        queryset = self.queryset.all()
        user = self.request.GET.get("user")
        if user:
            q_filter = Q()
            proj_set = set()
            user_obj = User.objects.filter(name=user).first()
            for pa_obj in user_obj.proj_admin.all():
                pa_name = pa_obj.name
                if pa_name in proj_set:
                    continue
                proj_set.add(pa_name)
                q_filter = q_filter|Q(name=pa_name)
            for query_obj in Flow.objects.filter(owner__name=user):
                proj_name = query_obj.block.proj.name
                if proj_name in proj_set:
                    continue
                proj_set.add(query_obj.block.proj.name)
                q_filter = q_filter|Q(name=proj_name)
            queryset = queryset.filter(q_filter) if q_filter else queryset.none()
        return queryset

class ProjDetail(generics.RetrieveAPIView):
    """flow report project detail"""
    queryset = Proj.objects.all()
    serializer_class = ProjRelatedSerializer

class BlockList(generics.ListAPIView):
    """flow report block list"""
    queryset = Block.objects.all()
    serializer_class = BlockSerializer
    def get_queryset(self, *args, **kwargs):
        name = self.request.GET.get("block")
        proj = self.request.GET.get("proj")
        queryset = self.queryset.filter(name=name) if name else self.queryset.all()
        queryset = queryset.filter(proj__name=proj) if proj else queryset
        return queryset

class BlockDetail(generics.RetrieveAPIView):
    """flow report block detail"""
    queryset = Block.objects.all()
    serializer_class = BlockRelatedSerializer

class FlowList(generics.ListAPIView):
    """flow report flow list"""
    queryset = Flow.objects.all()
    serializer_class = FlowSerializer
    def get_queryset(self, *args, **kwargs):
        name = self.request.GET.get("flow")
        block = self.request.GET.get("block")
        proj = self.request.GET.get("proj")
        owner = self.request.GET.get("owner")
        queryset = self.queryset.filter(name=name) if name else self.queryset.all()
        queryset = queryset.filter(block__name=block) if block else queryset
        queryset = queryset.filter(block__proj__name=proj) if proj else queryset
        queryset = queryset.filter(owner__name=owner) if owner else queryset
        return queryset

class FlowDetail(generics.RetrieveAPIView):
    """flow report flow detail"""
    queryset = Flow.objects.all()
    serializer_class = FlowRelatedSerializer

class FlowStatusList(generics.ListAPIView):
    """flow report flow status list"""
    queryset = Flow.objects.all()
    serializer_class = FlowStatusSerializer
    def get_queryset(self, *args, **kwargs):
        queryset = self.queryset.all()
        user = self.request.GET.get("user")
        if user:
            q_filter = Q(owner__name=user)
            user_obj = User.objects.filter(name=user).first()
            for pa_obj in user_obj.proj_admin.all():
                q_filter = q_filter|Q(block__proj__name=pa_obj.name)
            queryset = queryset.filter(q_filter)
        if queryset:
            fct = queryset.first().created_time
            queryset = queryset.filter(created_time__gte=fct-tz.timedelta(weeks=1))
        return queryset

class FlowStatusDetail(generics.RetrieveAPIView):
    """flow report flow status detail"""
    queryset = Flow.objects.all()
    serializer_class = FlowStatusRelatedSerializer

class StageList(generics.ListAPIView):
    """flow report stage list"""
    queryset = Stage.objects.all()
    serializer_class = StageSerializer
    def get_queryset(self, *args, **kwargs):
        name = self.request.GET.get("stage")
        flow = self.request.GET.get("flow")
        block = self.request.GET.get("block")
        proj = self.request.GET.get("proj")
        owner = self.request.GET.get("owner")
        queryset = self.queryset.filter(name=name) if name else self.queryset.all()
        queryset = queryset.filter(flow__name=flow) if flow else queryset
        queryset = queryset.filter(flow__block__name=block) if block else queryset
        queryset = queryset.filter(flow__block__proj__name=proj) if proj else queryset
        queryset = queryset.filter(owner__name=owner) if owner else queryset
        return queryset

class StageDetail(generics.RetrieveAPIView):
    """flow report stage detail"""
    queryset = Stage.objects.all()
    serializer_class = StageDetailSerializer

class UserList(generics.ListCreateAPIView):
    """flow report user list"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    def get_queryset(self, *args, **kwargs):
        name = self.request.GET.get("user")
        return self.queryset.filter(name=name) if name else self.queryset.all()

class UserDetail(generics.RetrieveAPIView):
    """flow report user detail"""
    queryset = User.objects.all()
    serializer_class = UserRelatedSerializer

class RunnerProj(views.APIView):
    """runner platform post proj info"""
    def post(self, request, format=None):
        proj_name = request.data.get("proj")
        owner_name = request.data.get("owner")
        if not proj_name:
            return Response({"message": "proj name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if owner_name:
            owner_obj, _ = User.objects.get_or_create({"name": owner_name}, name=owner_name)
        else:
            owner_obj = None
        proj_obj, created_flg = Proj.objects.update_or_create(
            {"name": proj_name, "owner": owner_obj, "data": request.data.get("data", {})}, name=proj_name)
        return Response({"proj_name": proj_obj.name, "created_flg": created_flg})

class RunnerBlock(views.APIView):
    """runner platform post block info"""
    def post(self, request, format=None):
        block_name = request.data.get("block")
        proj_name = request.data.get("proj")
        owner_name = request.data.get("owner")
        if not block_name:
            return Response({"message": "block name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not proj_name:
            return Response({"message": "proj name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if owner_name:
            owner_obj, _ = User.objects.get_or_create({"name": owner_name}, name=owner_name)
        else:
            owner_obj = None
        proj_obj, _ = Proj.objects.get_or_create({"name": proj_name}, name=proj_name)
        block_obj, created_flg = Block.objects.update_or_create(
            {"name": block_name, "owner": owner_obj, "proj": proj_obj, "data": request.data.get("data", {})},
            name=block_name, proj=proj_obj)
        return Response({"block_name": block_obj.name, "created_flg": created_flg})

class RunnerFlow(views.APIView):
    """runner platform post flow info"""
    def post(self, request, format=None):
        flow_name = request.data.get("flow")
        block_name = request.data.get("block")
        proj_name = request.data.get("proj")
        owner_name = request.data.get("owner")
        created_time = request.data.get("created_time", "")
        created_time = pytz.timezone(settings.TIME_ZONE).localize(dateutil.parser.parse(
            created_time) if created_time else tz.datetime.now())
        status = request.data.get("status", "")
        comment = request.data.get("comment", "")
        if not flow_name:
            return Response({"message": "flow name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not block_name:
            return Response({"message": "block name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not proj_name:
            return Response({"message": "proj name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not owner_name:
            return Response({"message": "owner name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        owner_obj, _ = User.objects.get_or_create({"name": owner_name}, name=owner_name)
        proj_obj, _ = Proj.objects.get_or_create({"name": proj_name}, name=proj_name)
        block_obj, _ = Block.objects.get_or_create(
            {"name": block_name, "proj": proj_obj}, name=block_name, proj=proj_obj)
        flow_obj, created_flg = Flow.objects.update_or_create(
            {"name": flow_name, "block": block_obj, "owner": owner_obj,
             "created_time": created_time, "status": status, "comment": comment,
             "data": request.data.get("data", {})},
            name=flow_name, block=block_obj, owner=owner_obj, created_time=created_time)
        return Response({"flow_name": flow_obj.name, "created_flg": created_flg})

class RunnerStage(views.APIView):
    """runner platform post stage info"""
    def post(self, request, format=None):
        stage_name = request.data.get("stage")
        flow_name = request.data.get("flow")
        block_name = request.data.get("block")
        proj_name = request.data.get("proj")
        owner_name = request.data.get("owner")
        created_time = request.data.get("created_time", "")
        created_time = pytz.timezone(settings.TIME_ZONE).localize(dateutil.parser.parse(
            created_time) if created_time else tz.datetime.now())
        status = request.data.get("status", "")
        version = request.data.get("version", "")
        f_created_time = request.data.get("f_created_time", "")
        f_created_time = pytz.timezone(settings.TIME_ZONE).localize(dateutil.parser.parse(
            f_created_time) if f_created_time else tz.datetime.now())
        if not stage_name:
            return Response({"message": "stage name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not flow_name:
            return Response({"message": "flow name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not block_name:
            return Response({"message": "block name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not proj_name:
            return Response({"message": "proj name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not owner_name:
            return Response({"message": "owner name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        owner_obj, _ = User.objects.get_or_create({"name": owner_name}, name=owner_name)
        proj_obj, _ = Proj.objects.get_or_create({"name": proj_name}, name=proj_name)
        block_obj, _ = Block.objects.get_or_create(
            {"name": block_name, "proj": proj_obj}, name=block_name, proj=proj_obj)
        flow_obj, _ = Flow.objects.get_or_create(
            {"name": flow_name, "block": block_obj, "owner": owner_obj,
             "created_time": f_created_time},
            name=flow_name, block=block_obj, owner=owner_obj, created_time=f_created_time)
        stage_obj, created_flg = Stage.objects.update_or_create(
            {"name": stage_name, "owner": owner_obj,
             "created_time": created_time, "status": status, "version": version,
             "data": request.data.get("data", {})},
            name=stage_name, owner=owner_obj, created_time=created_time)
        stage_obj.flow.add(flow_obj)
        return Response({"stage_name": stage_obj.name, "created_flg": created_flg})

class RunnerUpload(views.APIView):
    """runner platform upload files"""
    def post(self, request, format=None):
        file_obj = request.FILES.get("file_obj")
        stage_name = request.data.get("stage")
        flow_name = request.data.get("flow")
        block_name = request.data.get("block")
        proj_name = request.data.get("proj")
        owner_name = request.data.get("owner")
        created_time = request.data.get("created_time", "")
        if not file_obj:
            return Response({"message": "file content is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not stage_name:
            return Response({"message": "stage name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not flow_name:
            return Response({"message": "flow name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not block_name:
            return Response({"message": "block name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not proj_name:
            return Response({"message": "proj name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        if not owner_name:
            return Response({"message": "owner name is NA"}, status=status.HTTP_400_BAD_REQUEST)
        file_name = os.path.basename(file_obj.name)
        tar_dir = os.path.join("flow_rpt", owner_name, proj_name, block_name, f"{flow_name}__{stage_name}")
        url_tar_dir = os.path.join(settings.MEDIA_URL, tar_dir)
        real_tar_dir = os.path.join(settings.MEDIA_ROOT, tar_dir)
        ts_file_name = f"{created_time}__{file_name}"
        os.makedirs(real_tar_dir, exist_ok=True)
        with open(os.path.join(real_tar_dir, ts_file_name), "wb+") as r_f:
            shutil.copyfileobj(file_obj, r_f)
        return Response({"file_url": os.path.join(url_tar_dir, ts_file_name)})