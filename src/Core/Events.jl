
function EventHandlers(kind::String, d::Dict)

    hs=[]
    for (k,v) in d
        if v isa NamedTuple
           kis = keys(v)
           @assert :args in kis && :script in kis "Building EventHandler from NamedTuple requires both `args` and `script` keys"
           @assert v.args isa Vector "Function `args` must be of Type Vector{String}. `$(v.args)` of type $(typeof(v.args)) provided."
           push!(hs, CustomEventHandler(kind, k, v.args, v.script, "", ""))
        elseif v isa String
           push!(hs,CustomEventHandler(kind,k,[],v,"",""))
        end
    end
    function_script!.(hs)
    return hs
end

function create_events(events::NamedTuple)
    hs=[]
    append!(hs, EventHandlers("methods", events.methods))
    append!(hs, EventHandlers("computed",events.computed))
    append!(hs, EventHandlers("watched", events.watched))
    return hs
end

js_closure = function(;scope::String="@scope@")
    script=""" for (key of Object.keys($scope)) {
        eval("var "+key+" = $scope."+key)
    };"""
    return script
end

function_script!(eh::EventHandler)=nothing

function function_script!(eh::CustomEventHandler)

        if eh.path==""
            scope="app_state"
        else
            scope="app_state."*eh.path
        end

        args = size(eh.args, 1) > 0 ? join(eh.args, ",") : "event"

        str="""$(eh.id) :(function($args) {
            $(js_closure(scope=scope))
        return  function($args) {
          $(eh.script)
        };
        })()
        """

    eh.function_script=str

    return nothing
end

function events_script(vs::VueStruct)
    els=[]
    for e in ["methods","computed","watched"]
        ef=filter(x->x.kind==e,vs.events)
        if length(ef)!=0
            push!(els,"$e : {"*join(map(y->y.function_script,ef),",")*"}")
        end
    end
    return join(els,",")
end

function get_json_attr(d::Dict,a::String,path="app_state")
    out=Dict()
    for (k,v) in d
        if v isa Dict
            if haskey(v,a)
                out[k]=path*".$k.$a"
            else
                ret=get_json_attr(v,a,path*".$k")
                length(ret)!=0 ? out[k]=ret : nothing
            end
        end
    end
    return out
end

function std_events!(vs::VueStruct, new_es::Vector{EventHandler})

    ##xhr
    function_script = """xhr : function(contents, url=window.location.pathname, method="POST", async=true, success="", error="") {

    console.log(contents)
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
        if (this.readyState == 4) {
            if (this.status == 200) {
                success != "" ? success : console.log(this.responseText);
            } else {
                error != "" ? error : console.log('Status: ' + this.status + ' ' + this.statusText + ' : ' + this.responseText);
            }
        }
    }
    xhr.open(method, url, async);
    xhr.send(contents);
    }
    """
    push!(new_es,StdEventHandler("methods","xhr","",function_script))

    ## Submit Method
    value_script=replace(JSON.json(get_json_attr(vs.def_data,"value")),"\""=>"")
    function_script="""submit : function(context, url, method, async, success, error) {
        var ret=$value_script
        $(js_closure(scope="app"))
        if (context && context.length > 0) {
            out = {}
            for (key in ret) {
                if (context.includes(key)) {
                    out[key] = ret[key]
                }
            }
            ret = out
        }
        return xhr(JSON.stringify(ret), url, method, async, success, error)
    }"""
    push!(new_es,StdEventHandler("methods","submit","",function_script))

    ## Open Method
    function_script="""open : function(url,name) {
        name = typeof name !== 'undefined' ? name : '_self';
        window.open(url,name);
        }"""

    push!(new_es,StdEventHandler("methods","open","",function_script))

    ## Datatable Col Render
    function_script="""datatable_col_render : function(item,render_script) {
        return render_script(item)
        }"""

    push!(new_es,StdEventHandler("methods","datatable_col_render","",function_script))

    return nothing
end

"""
Wrapper around submit and xhr method(s)
Allows submissions to be defined at VueElement level as an action, `onclick`, `onchange`, etc
### Examples
```julia
@el(lun,"v-text-field",value="Luanda",label="Luanda",disabled=false)
@el(opo,"v-text-field",value="Oporto",label="Oporto")
@el(sub, "v-btn", value="Submit All", click=submit("api", context=[lun, opo],
    success="this.window.alert('teste');", error="this.console.log('teste');"))
```
"""
function submit(
    url::String;
    method::String="POST",
    async::Bool=true,
    success::String="",
    error::String="",
    context::Union{Nothing, Vector}=nothing,
    )
    success = success != "" ? "(function() {$success})()" : "\'$success\'"
    error = error != "" ? "(function() {$error})()" : "\'$error\'"
    contents = context != nothing ? [x.id for x in context] : []
    return "submit($(contents != [] ? replace(JSON.json(contents), "\""=>"'") : "null"), '$url', '$method', $async, $success, $error)"
end
