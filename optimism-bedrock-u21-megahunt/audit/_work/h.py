# helper for F3 fragments. Each fragment file defines REPORT (dict) and calls F(...) to append records.
RECS=[]; REPORTS={}
def REPORT(key, **kw):
    REPORTS[key]=kw
def F(rep,fid,sev,smap,title,rc,contracts,funcs,state,attacker,impact,fix,status,page,
      fix_commit="not stated",tests="not stated",residual="",siblings="",later="",scope=None,oos=None,commit=None):
    r=REPORTS[rep]
    RECS.append(dict(report=rep,finding_id=fid,severity_original=sev,severity_current_mapping=smap,title=title,
      root_cause_class=rc,affected_contracts=contracts,affected_functions=funcs,required_state=state,
      attacker_model=attacker,impact=impact,exact_commit=commit or r.get('commit','not stated'),fix_commit=fix_commit,
      fix_strategy=fix,tests_added=tests,scope_assumptions=scope or r.get('scope',''),
      explicit_out_of_scope=oos or r.get('oos',''),residual_assumptions=residual,sibling_paths_not_reviewed=siblings,
      later_releases_that_retouch_root_cause=later,status=status,page_ref=page))
