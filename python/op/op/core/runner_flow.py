"""
Author: Guanyu Yi @ OnePiece Platform Group
Email: guanyu_yi@alchip.com
Description: flow related features
"""

import os
import subprocess
from utils import pcom
from utils import settings
from utils import env_boot
from core import lib_map

LOG = pcom.gen_logger(__name__)

class FlowProc(env_boot.EnvBoot, lib_map.LibMap):
    """flow processor for blocks"""
    def __init__(self):
        super().__init__()
        self.boot_env()
        self.ch_cfg_dic = {}
        self.liblist_var_dic = {}
        self.oprun_file_lst = []
    def list_env(self):
        """to list all current project or block op environment variables"""
        LOG.info(f":: {os.linesep}all op internal env variables")
        pcom.pp_list(self.ced)
    def list_blk(self):
        """to list all possible blocks according to project root dir"""
        blk_ignore_str = "|".join(settings.BLK_IGNORE_LST)
        run_str = f"tree -L 1 -d -I '(|{blk_ignore_str}|)' {self.ced['PROJ_ROOT']}"
        tree_str = subprocess.run(
            run_str, shell=True, check=True, stdout=subprocess.PIPE).stdout.decode()
        LOG.info(f":: {os.linesep}all available blocks")
        pcom.pp_list(tree_str, True)
    def list_stage(self):
        """to list all current project or block available stages"""
        LOG.info(f":: {os.linesep}all current available stages")
        stage_dic = {}
        for cfg_k, cfg_v in self.cfg_dic.items():
            if cfg_k in pcom.rd_cfg(self.cfg_dic.get("proj", {}), "flow", "not_flow_cfg"):
                continue
            cfg_v_lst = list(dict(cfg_v))
            cfg_v_lst.remove("DEFAULT")
            stage_dic[cfg_k] = cfg_v_lst
        pcom.pp_list(stage_dic)
    def proc_cfg(self):
        """to process project or block cfg for next step usage"""
        for cfg_k, cfg_v in self.cfg_dic.items():
            if cfg_k == "lib":
                try:
                    self.liblist_var_dic = self.gen_liblist(
                        self.ced["PROJ_LIB"], self.ced["RUN_SRC"],
                        self.dir_cfg_dic["lib"]["liblist"], self.cfg_dic["lib"])
                except KeyError as err:
                    LOG.error(err)
                    raise SystemExit()
        for cfg_k, cfg_v in self.cfg_dic.items():
            self.ch_cfg_dic[cfg_k] = pcom.ch_cfg(cfg_v)
    def proc_tmp(self, gen_lst):
        """to process project and block templates to generate run files"""
        if not self.blk_flg:
            LOG.error("it's not in a block directory, please cd into one")
            raise SystemExit()
        for cfg_k, cfg_v in self.ch_cfg_dic.items():
            if cfg_k in pcom.rd_cfg(self.cfg_dic.get("proj", {}), "flow", "not_flow_cfg"):
                continue
            for proj_tmp in pcom.find_iter(
                    f"{self.ced['PROJ_SHARE_TMP']}{os.sep}{cfg_k}", "*"):
                if gen_lst:
                    if cfg_k not in gen_lst:
                        continue
                dst_file = proj_tmp.replace(
                    self.ced["PROJ_SHARE_TMP"], self.ced["RUN_SRC"])
                dst_file_name = os.path.basename(proj_tmp)
                if dst_file_name in cfg_v:
                    LOG.info(f":: generating run file {dst_file} ...")
                    cfg_sec = cfg_v[dst_file_name]
                    pcom.ren_tempfile(
                        LOG, proj_tmp, dst_file,
                        {"global": self.ch_cfg_dic.get("proj", {}), "env": self.ced,
                         "local": cfg_sec, "liblist": self.liblist_var_dic}
                    )
                    if "_exec_tool" in cfg_sec:
                        with open(f"{dst_file}.oprun", "w") as orf:
                            orf.write(
                                f"{cfg_sec.get('_exec_tool')} {cfg_sec.get('_exec_opts', '')} "
                                f"{dst_file}{os.linesep}"
                            )
                        self.oprun_file_lst.append(f"{dst_file}.oprun")
                else:
                    LOG.warning(
                        f" template {proj_tmp} has no corresponding config section "
                        f"{dst_file_name} in config {cfg_k}"
                    )
    def proc_run(self, run_lst):
        """to process generated oprun files for running flows"""
        if not self.blk_flg:
            LOG.error("it's not in a block directory, please cd into one")
            raise SystemExit()
        if run_lst == []:
            oprun_lst = self.oprun_file_lst
        elif run_lst:
            oprun_lst = []
            for run_kw in run_lst:
                oprun_lst.extend([c_c for c_c in self.oprun_file_lst if c_c.startswith(
                    f"{self.ced['RUN_SRC']}{os.sep}{run_kw}")])
        for oprun_file in oprun_lst:
            stage_str = os.path.basename(os.path.dirname(oprun_file))
            LOG.info(f":: running stage {stage_str}, oprun file {oprun_file} ...")
            subprocess.run(
                f"xterm -title '{oprun_file}' -e 'source {oprun_file}'", shell=True
            )

def run_flow(args):
    """to run flow sub cmd"""
    f_p = FlowProc()
    if args.flow_list_env:
        f_p.list_env()
    elif args.flow_list_blk:
        f_p.list_blk()
    elif args.flow_list_stage:
        f_p.list_stage()
    elif args.flow_gen_lst != None:
        f_p.proc_cfg()
        f_p.proc_tmp(args.flow_gen_lst)
    elif args.flow_run_lst != None:
        f_p.proc_cfg()
        f_p.proc_tmp(args.flow_run_lst)
        f_p.proc_run(args.flow_run_lst)
    else:
        LOG.critical("no actions specified in op flow sub cmd")
        raise SystemExit()
