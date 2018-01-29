"""
Author: Guanyu Yi @ OnePiece Platform Group
Email: guanyu_yi@alchip.com
Description: base class for processing projects from code repo
"""

import os
import git
from utils import pcom
from utils import settings

LOG = pcom.gen_logger(__name__)

class ProjRepo(object):
    """base calss of projects from code repo"""
    def __init__(self):
        self.all_proj_dic = all_proj_dic = settings.ALL_PROJ_DIC
        self.all_proj_lst = sorted(list(all_proj_dic))
        self.repo_dic = {}
    def list_proj(self):
        """to list all projects registered in op"""
        LOG.info(f":: {os.linesep}all available projects")
        pcom.pp_list(self.all_proj_lst)
    def git_proj(self):
        """to check out project by using git"""
        try:
            self.repo_dic["repo"] = repo = git.Repo.init(self.repo_dic["repo_dir"])
        except PermissionError as err:
            LOG.error(err)
            raise SystemExit()
        rmt = repo.remote() if repo.remotes else repo.create_remote(
            "origin", self.repo_dic["repo_url"])
        LOG.info(
            f":: git pulling project {self.repo_dic['init_proj_name']} "
            f"from repository to {self.repo_dic['repo_dir']} ..."
        )
        pcom.cfm()
        rmt.pull("master")
        LOG.info(f"please run op cmds under the project dir {self.repo_dic['repo_dir']}")
        #TODO to process user auth actions
        # u_n = getpass.getuser()
        # p_w = getpass.getpass("git password: ")
    def svn_proj(self):
        """to check out project by using svn"""
        pass
    def repo_proj(self, init_proj_name):
        """to operate project from code repo"""
        self.repo_dic["init_proj_name"] = init_proj_name
        try:
            self.repo_dic["repo_url"] = self.all_proj_dic[init_proj_name]
        except KeyError:
            LOG.error(f"project name must be one of {self.all_proj_lst}")
            raise SystemExit()
        self.repo_dic["repo_dir"] = os.getcwd()
        if settings.PROJ_REPO == "git":
            self.git_proj()
        elif settings.PROJ_REPO == "svn":
            self.svn_proj()
