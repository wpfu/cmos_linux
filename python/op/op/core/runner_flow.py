"""
Author: Guanyu Yi @ OnePiece Platform Group
Email: guanyu_yi@alchip.com
Description: flow related features
"""

import os
import shutil
import subprocess
import json
from utils import pcom
from utils import settings
from utils import env_boot
from core import lib_map
from core import log_par

LOG = pcom.gen_logger(__name__)

def exp_stages(s_lst, cfg, sec, p_s=None):
    """to expand stages details of flow config"""
    if sec == "" or p_s == "":
        return s_lst
    pre_flow = pcom.rd_cfg(cfg, sec, "pre_flow", True)
    pre_stage = pcom.rd_cfg(cfg, sec, "pre_stage", True)
    stage_lst = pcom.rd_cfg(cfg, sec, "stages")
    if p_s and p_s not in stage_lst:
        LOG.error(f"stage {p_s} not in flow {sec}")
        raise SystemExit()
    if p_s:
        stage_lst = stage_lst[:stage_lst.index(p_s)+1]
    stage_lst = [
        {"flow": sec, "stage": c_c.split(":")[0].strip(), "sub_stage": c_c.split(":")[-1].strip()}
        for c_c in stage_lst if c_c]
    stage_lst.extend(s_lst)
    return exp_stages(stage_lst, cfg, pre_flow, pre_stage)

class FlowProc(env_boot.EnvBoot, lib_map.LibMap, log_par.LogParser):
    """flow processor for blocks"""
    def __init__(self):
        super().__init__()
        self.boot_env()
        self.ver_dic = {}
        self.opvar_lst = []
        self.run_flg = False
        self.force_flg = False
    def list_env(self):
        """to list all current project or block op environment variables"""
        LOG.info(":: all op internal env variables")
        pcom.pp_list(self.ced)
    def list_blk(self):
        """to list all possible blocks according to project root dir"""
        blk_ignore_str = "|".join(settings.BLK_IGNORE_LST)
        run_str = f"tree -L 1 -d -I '(|{blk_ignore_str}|)' {self.ced['PROJ_ROOT']}"
        tree_str = subprocess.run(
            run_str, shell=True, check=True, stdout=subprocess.PIPE).stdout.decode()
        LOG.info(":: all available blocks")
        pcom.pp_list(tree_str, True)
    def list_flow(self):
        """to list all current block available flows"""
        LOG.info(":: all current available flows of block")
        lf_dic = {}
        for sec_k in self.cfg_dic.get("flow", {}):
            lf_lst = []
            for flow_dic in exp_stages([], self.cfg_dic["flow"], sec_k):
                flow_name = flow_dic.get("flow", "")
                stage_name = flow_dic.get("stage", "")
                sub_stage_name = flow_dic.get("sub_stage", "")
                lf_lst.append(f"{flow_name}::{stage_name}:{sub_stage_name}")
            lf_dic[sec_k] = lf_lst
        pcom.pp_list(lf_dic)
    def init(self, init_lst):
        """to perform flow initialization"""
        for init_name in init_lst:
            if init_name == "DEFAULT":
                continue
            LOG.info(f":: initializing flow {init_name} directories ...")
            parent_flow = pcom.rd_cfg(self.cfg_dic.get("flow", {}), init_name, "pre_flow", True)
            if not parent_flow:
                parent_flow = "DEFAULT"
            src_dir = f"{self.ced['BLK_CFG_FLOW']}{os.sep}{parent_flow}"
            dst_dir = f"{self.ced['BLK_CFG_FLOW']}{os.sep}{init_name}"
            if not os.path.isdir(src_dir):
                LOG.error(f"parent flow directory {src_dir} is NA")
                raise SystemExit()
            if os.path.isdir(dst_dir):
                LOG.info(
                    f"initializing flow directory {dst_dir} already exists, "
                    f"please confirm to overwrite the previous flow config and plugins")
                pcom.cfm()
                shutil.rmtree(dst_dir, True)
            shutil.copytree(src_dir, dst_dir)
    def proc_ver(self):
        """to process class flow version directory"""
        for sec_k, sec_v in self.cfg_dic.get("flow", {}).items():
            self.ver_dic[sec_k] = {}
            for opt_k, opt_v in sec_v.items():
                if not opt_v:
                    continue
                if opt_k.startswith("VERSION_"):
                    ver_key = opt_k.replace("VERSION_", "").lower()
                    key_dir = f"{self.ced['BLK_ROOT']}{os.sep}{ver_key}{os.sep}{opt_v}"
                    if not os.path.isdir(key_dir):
                        LOG.error(
                            f"{ver_key} version dir {key_dir} is NA, "
                            f"defined in flow config section {sec_k}")
                        raise SystemExit()
                    if not os.listdir(key_dir):
                        LOG.error(
                            f"{ver_key} version dir {key_dir} is empty, "
                            f"defined in flow config section {sec_k}")
                        raise SystemExit()
                    self.ver_dic[sec_k][ver_key] = opt_v
    def proc_prex(self, stage_dic):
        """to process prex defined directory in proj.cfg"""
        flow_root_dir = stage_dic["flow_root_dir"]
        prex_dir_sec = (
            self.cfg_dic["proj"]["prex_dir"]
            if "prex_dir" in self.cfg_dic["proj"] else {})
        prex_dir_dic = {}
        for prex_dir_k in prex_dir_sec:
            prex_dir = pcom.ren_tempstr(
                LOG, pcom.rd_sec(prex_dir_sec, prex_dir_k, True),
                {"flow_root_dir": flow_root_dir})
            pcom.mkdir(LOG, prex_dir)
            prex_dir_dic[prex_dir_k] = prex_dir
        for prex_dir_k, prex_dir_v in prex_dir_dic.items():
            if prex_dir_k in stage_dic:
                continue
            stage_dic[prex_dir_k] = prex_dir_v
    def proc_flow_lst(self, flow_lst):
        """to process flow list from arguments"""
        if not self.blk_flg:
            LOG.error("it's not in a block directory, please cd into one")
            raise SystemExit()
        if not flow_lst:
            flow_lst = ["DEFAULT"]
        for flow in flow_lst:
            if flow not in self.cfg_dic.get("flow", {}):
                LOG.error(f"flow {flow} is NA in flow.cfg")
                raise SystemExit()
            self.proc_flow(flow)
    def proc_flow(self, flow):
        """to process particular flow"""
        v_net = self.ver_dic.get(flow, {}).get("netlist", "")
        if not v_net:
            LOG.error(f"netlist version of flow {flow} is NA in flow.cfg")
            raise SystemExit()
        proj_tmp_dir = self.ced["PROJ_SHARE_TMP"].rstrip(os.sep)
        flow_liblist_dir = os.path.join(self.ced["BLK_RUN"], f"v{v_net}", flow, "liblist")
        liblist_var_dic = self.gen_liblist(
            self.ced["PROJ_LIB"], flow_liblist_dir,
            self.dir_cfg_dic["lib"]["DEFAULT"]["liblist"],
            self.cfg_dic["lib"][flow] if flow in self.cfg_dic["lib"]
            else self.cfg_dic["lib"]["DEFAULT"])
        pre_stage_dic = {}
        pre_file_mt = 0.0
        for flow_dic in exp_stages([], self.cfg_dic["flow"], flow):
            flow_name = flow_dic.get("flow", "")
            stage_name = flow_dic.get("stage", "")
            sub_stage_name = flow_dic.get("sub_stage", "")
            tmp_file = os.path.join(proj_tmp_dir, "flow", stage_name, sub_stage_name)
            if not os.path.isfile(tmp_file):
                LOG.warning(
                    f"template file {tmp_file} is NA, "
                    f"used by flow {flow_name} stage {stage_name}")
                continue
            flow_root_dir = f"{self.ced['BLK_RUN']}{os.sep}v{v_net}{os.sep}{flow_name}"
            local_dic = pcom.ch_cfg(
                self.dir_cfg_dic.get("flow", {}).get(flow_name, {}).get(stage_name, {})).get(
                    sub_stage_name, {})
            stage_dic = {
                "flow": flow_name, "stage": stage_name, "sub_stage": sub_stage_name,
                "flow_root_dir": flow_root_dir, "flow_liblist_dir": flow_liblist_dir,
                "flow_scripts_dir": f"{flow_root_dir}{os.sep}scripts",
                "config_plugins_dir":
                f"{self.ced['BLK_CFG_FLOW']}{os.sep}{flow_name}{os.sep}plugins"}
            self.proc_prex(stage_dic)
            tmp_dic = {
                "global": pcom.ch_cfg(self.cfg_dic["proj"]), "env": self.ced,
                "local": local_dic, "liblist": liblist_var_dic,
                "cur": stage_dic, "pre": pre_stage_dic, "ver": self.ver_dic.get(flow, {})}
            multi_inst_lst = [c_c.strip() for c_c in pcom.rd_cfg(
                self.dir_cfg_dic.get("flow", {}).get(flow_name, {}).get(stage_name, {}),
                sub_stage_name, "_multi_inst") if c_c.strip()]
            if not multi_inst_lst:
                multi_inst_lst = [""]
            for multi_inst in multi_inst_lst:
                dst_file = os.path.join(
                    flow_root_dir, "scripts", stage_name, multi_inst,
                    sub_stage_name) if multi_inst else os.path.join(
                        flow_root_dir, "scripts", stage_name, sub_stage_name)
                local_dic["_multi_inst"] = multi_inst
                LOG.info(f":: generating run file {dst_file} ...")
                pcom.ren_tempfile(LOG, tmp_file, dst_file, tmp_dic)
                if "_exec_cmd" in local_dic:
                    tool_str = local_dic.get("_exec_tool", "")
                    job_str = (
                        f"{local_dic.get('_job_cmd', '')} {local_dic.get('_job_queue', '')} "
                        f"{local_dic.get('_job_cpu_number', '')} "
                        f"{local_dic.get('_job_resource', '')}"
                        if "_job_cmd" in local_dic else "")
                    jn_str = (
                        f"""{job_str} -J '{self.ced["USER"]}:{flow_name}:"""
                        f"""{stage_name}:{sub_stage_name}:{multi_inst}'""") if job_str else ""
                    cmd_str = local_dic.get("_exec_cmd", "")
                    with open(f"{dst_file}.oprun", "w") as orf:
                        orf.write(
                            f"{tool_str} {jn_str} {cmd_str} {dst_file}{os.linesep}")
                    err_kw_lst = pcom.rd_cfg(
                        self.cfg_dic.get("filter", {}), stage_name, "exp_error_keywords")
                    wav_kw_lst = pcom.rd_cfg(
                        self.cfg_dic.get("filter", {}), stage_name, "exp_waiver_keywords")
                    filter_dic = {"err_kw_lst": err_kw_lst, "wav_kw_lst": wav_kw_lst}
                    if self.run_flg:
                        file_mt = os.path.getmtime(dst_file)
                        f_flg = False if file_mt > pre_file_mt else True
                        if self.force_flg:
                            f_flg = True
                        if f_flg:
                            # updated timestamp to fit auto-skip feature
                            os.utime(dst_file)
                            # following stages have to be forced run
                            file_mt = os.path.getmtime(dst_file)
                        self.proc_run(
                            {"file": f"{dst_file}.oprun", "flow": flow_name,
                             "stage": stage_name, "sub_stage": sub_stage_name,
                             "multi_inst": multi_inst, "filter_dic": filter_dic}, f_flg)
                    else:
                        file_mt = 0.0
            self.opvar_lst.append(
                {"local": local_dic, "cur": stage_dic, "pre": pre_stage_dic,
                 "ver": self.ver_dic.get(flow, {})})
            pre_stage_dic = stage_dic
            pre_file_mt = file_mt
    def proc_run(self, run_dic, f_flg=True):
        """to process generated oprun files for running flows"""
        run_file = run_dic.get("file", "")
        if not os.path.isfile(run_file):
            LOG.error(f"run file {run_file} is NA")
            raise SystemExit()
        run_filter_dic = run_dic.get("filter_dic", {})
        run_file_dir = os.path.dirname(run_file)
        run_file_base = os.path.basename(run_file)
        run_json = f"{run_file_dir}{os.sep}.{run_file_base}.json"
        run_pass = f"{run_file_dir}{os.sep}.{run_file_base}.pass"
        run_src_file = os.path.splitext(run_file)[0]
        file_mt = os.path.getmtime(run_src_file)
        LOG.info(
            f":: running flow {run_dic['flow']}::{run_dic['stage']}:{run_dic['sub_stage']}:"
            f"{run_dic['multi_inst']}, oprun log {run_file}.log ...")
        if not f_flg and os.path.isfile(run_pass) and os.path.getmtime(run_pass) > file_mt:
            LOG.info(f"passed and re-run skipped")
            if os.path.isfile(run_json) and os.path.getmtime(run_json) > file_mt:
                with open(run_json) as rjf:
                    log_dic = json.load(rjf)
            return
        trash_dir = f"{os.path.dirname(run_file)}{os.sep}.trash"
        pcom.mkdir(LOG, trash_dir)
        tail_str = " &" if run_dic['multi_inst'] else ""
        subprocess.run(
            f"xterm -title '{run_file}' -e 'cd {trash_dir}; "
            f"source {run_file} | tee {run_file}.log'{tail_str}", shell=True)
        LOG.info(f"parsing log file {run_file}.log")
        log_dic = self.parse_run_log(f"{run_file}.log", run_filter_dic)
        with open(run_json, "w") as rjf:
            json.dump(log_dic, rjf)
        if log_dic.get("status", "") == "passed":
            open(run_pass, "w").close()
            LOG.info(f"passed")
        else:
            if os.path.isfile(run_pass):
                os.remove(run_pass)
            LOG.error(f"failed lines: {os.linesep}{os.linesep.join(log_dic['err_lst'])}")
            raise SystemExit()
        # query_url = f"{pcom.BE_URL}/pj_app/regr/db_query/query_insert_case/"
        # if pcom.BACKEND:
        #     requests.post(query_url, json=log_dic)
    def show_var(self):
        """to show all variables used in templates"""
        if not self.blk_flg:
            LOG.error("it's not in a block directory, please cd into one")
            raise SystemExit()
        LOG.info(f":: all templates used variables")
        pcom.pp_list(self.opvar_lst)

def run_flow(args):
    """to run flow sub cmd"""
    f_p = FlowProc()
    if args.flow_list_env:
        f_p.list_env()
    elif args.flow_list_blk:
        f_p.list_blk()
    elif args.flow_list_flow:
        f_p.list_flow()
    elif args.flow_init_lst:
        f_p.init(args.flow_init_lst)
    elif args.flow_gen_lst != None:
        f_p.proc_ver()
        f_p.proc_flow_lst(args.flow_gen_lst)
    elif args.flow_run_lst != None:
        f_p.run_flg = True
        if args.flow_force:
            f_p.force_flg = True
        f_p.proc_ver()
        f_p.proc_flow_lst(args.flow_run_lst)
    elif args.flow_show_var_lst != None:
        f_p.proc_ver()
        f_p.proc_flow_lst(args.flow_show_var_lst)
        f_p.show_var()
    else:
        LOG.critical("no actions specified in op flow sub cmd")
        raise SystemExit()
