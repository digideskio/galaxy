<%inherit file="/base.mako"/>
<%namespace file="/message.mako" import="render_msg" />
<%namespace file="/admin/tool_shed_repository/common.mako" import="*" />
<%namespace file="/admin/tool_shed_repository/repository_actions_menu.mako" import="*" />

<%def name="stylesheets()">
    ${parent.stylesheets()}
    ${h.css( "dynatree_skin/ui.dynatree" )}
</%def>

<%def name="javascripts()">
    ${parent.javascripts()}
</%def>
${javascripts()}

%if message:
    ${render_msg( message, status )}
%endif
<script type="text/javascript">
<%
import json
metadata_json = json.dumps(repository['metadata'])
%>
var tool_html = '                    <tr style="display: table-row;" class="tool_row" parent="0" id="libraryItem">\
                            <td style="padding-left: 40px;">\
                                <div style="float:left;" class="menubutton split popup" id="tool">\
                                    <a class="view-info">__TOOL_NAME__</a>\
                                </div>\
                            </td>\
                        <td>__DESCRIPTION__</td>\
                        <td>__VERSION__</td>\
                    </tr>\
';
var repository_dependency_html = '                    <tr style="display: table-row;" class="datasetRow repository_dependency_row">\
                        <td style="padding-left: 60px;">Repository <b>__NAME__</b> revision <b>__REVISION__</b> owned by <b>__OWNER__</b> __PIR__</td>\
                    </tr>\
';
var tool_dependency_html = '                    <tr style="display: table-row;" class="datasetRow tool_dependency_row">\
                        <td style="padding-left: 40px;">__NAME__</td>\
                        <td>__VERSION__</td>\
                        <td>__TYPE__</td>\
                    </tr>\
'
    function check_tool_dependencies(metadata) {
        if (metadata['includes_tool_dependencies']) {
            $(".tool_dependency_row").remove();
            dependency_metadata = metadata['tool_dependencies'];
            for (var dependency_key in dependency_metadata) {
                dep = dependency_metadata[dependency_key];
                dependency_html = tool_dependency_html.replace('__NAME__', dep['name']);
                dependency_html = dependency_html.replace('__VERSION__', dep['version']);
                dependency_html = dependency_html.replace('__TYPE__', dep['type']);
                $("#tool_deps").append(dependency_html);
            }
            $("#tool_dependencies").show();
            $("#install_tool_dependencies").prop('disabled', false);
        }
        else {
            $("#tool_dependencies").hide();
            $("#install_tool_dependencies").prop('disabled', true);
        }
    }
    function check_repository_dependencies(metadata) {
        if (metadata['has_repository_dependencies']) {
            $(".repository_dependency_row").remove();
            dependency_metadata = metadata['repository_dependencies'];
            for (var dependency_key in dependency_metadata) {
                if (dependency_key != 'root_key' && dependency_key != 'description') {
                    for (var dependency in dependency_metadata[dependency_key]) {
                        dep = dependency_metadata[dependency_key][dependency];
                        toolshed = dep[0];
                        name = dep[1];
                        owner = dep[2];
                        changeset = dep[3];
                        prior = dep[4];
                        dependency_html = repository_dependency_html.replace('__NAME__', name);
                        dependency_html = dependency_html.replace('__REVISION__', changeset);
                        dependency_html = dependency_html.replace('__OWNER__', owner);
                        if (prior) {
                            dependency_html = dependency_html.replace('__PIR__', '(<i>prior installation required</i>)');
                        }
                        else {
                            dependency_html = dependency_html.replace('__PIR__', '');
                        }
                        $("#repository_deps").append(dependency_html);
                    }
                }
            }
            $("#repository_dependencies").show();
            $("#install_repository_dependencies").prop('disabled', false);
        }
        else {
            $("#repository_dependencies").hide();
            $("#install_repository_dependencies").prop('disabled', true);
        }
    }
    function tool_panel_section() {
        var tps_selection = $('#tool_panel_section_select').find("option:selected").text();
        if (tps_selection == 'Create New') {
            $("#new_tool_panel_section").prop('disabled', false);
            $("#new_tps").show();
        }
        else {
            $("#new_tool_panel_section").prop('disabled', true);
            $("#new_tps").hide();
        }
    }
    function repository_metadata() {
        metadata_key = $('#changeset').find("option:selected").text();
        var metadata = ${metadata_json}[metadata_key];
        if (!metadata['has_repository_dependencies'] && !metadata['includes_tool_dependencies']) {
            $("#dependencies").hide();
        }
        else {
            $("#dependencies").show();
        }
        check_tool_dependencies(metadata);
        check_repository_dependencies(metadata);
        $(".tool_row").remove();
        $.each(metadata['tools']['valid_tools'], function(idx) {
            new_html = tool_html.replace('__TOOL_NAME__', metadata['tools']['valid_tools'][idx]['name']);
            new_html = new_html.replace('__DESCRIPTION__', metadata['tools']['valid_tools'][idx]['description']);
            new_html = new_html.replace('__VERSION__', metadata['tools']['valid_tools'][idx]['version']);
            $("#tools_in_repo").append(new_html);
        });
    }
    function tps_switcher() {
        if ($(this).attr('id') == 'create_new') {
            $("#new_tool_panel_section").prop('disabled', false);
            $("#tool_panel_section_select").prop('disabled', true);
            $("#select_tps").hide(150);
            $("#new_tps").show(150);
        }
        else {
            $("#new_tool_panel_section").prop('disabled', true);
            $("#tool_panel_section_select").prop('disabled', false);
            $("#new_tps").hide(150);
            $("#select_tps").show(150);
        }
    }
    $(function() {
        repository_metadata();
        $("#new_tps").hide();
        $("#new_tool_panel_section").prop('disabled', true);
        $("#tool_panel_section_select").prop('disabled', false);
        $('#install_repository').click(function() {
            console.log($('#tool_panel_section_select').prop('disabled'));
            var params = {};
            params['tool_shed_url'] = $("#tool_shed_url").val();
            params['install_tool_dependencies'] = $("#install_tool_dependencies").val();
            params['install_repository_dependencies'] = $("#install_repository_dependencies").val();
            if ($('#tool_panel_section_select').prop('disabled')) {
                params['new_tool_panel_section'] = $("#new_tool_panel_section").val();
            }
            else{
                params['tool_panel_section_id'] = $('#tool_panel_section_select').find("option:selected").val();
            }
            params['changeset'] = $("#changeset").val();
            params['repo_dict'] = '${encoded_repository}';
            url = $('#repository_installation').attr('action');
            $.post(url, params, function(data) {
                window.location.href = data;
            });
        });
        $("#select_existing").click(tps_switcher);
        $("#create_new").click(tps_switcher);
        $('#changeset').change(repository_metadata);
        $("#tool_panel_section_select").change(tool_panel_section)
    });
</script>
<h1>${repository['owner']}/${repository['name']}</h1>
<form id="repository_installation" action="${h.url_for(controller='/api/tool_shed_repositories', action='install', async=True)}">
    <div class="toolForm">
        <div class="toolFormTitle">Changeset</div>
        <div class="toolFormBody">
    <select id="changeset" name="changeset">
        %for changeset in sorted( repository['metadata'].keys(), key=lambda changeset: int( changeset.split( ':' )[ 0 ] ), reverse=True ):
            <option value="${changeset.split(':')[1]}">${changeset}</option>
        %endfor
    </select>
    </div>
    </div>
    <input type="hidden" id="tsr_id" name="tsr_id" value="${repository['id']}" />
    <input type="hidden" id="tool_shed_url" name="tool_shed_url" value="${tool_shed_url}" />
    %if shed_tool_conf_select_field:
    <div class="toolForm">
        <div class="toolFormTitle">Shed tool configuration file:</div>
        <div class="toolFormBody">
        <%
            if len( shed_tool_conf_select_field.options ) == 1:
                select_help = "Your Galaxy instance is configured with 1 shed-related tool configuration file, so repositories will be "
                select_help += "installed using its <b>tool_path</b> setting."
            else:
                select_help = "Your Galaxy instance is configured with %d shed-related tool configuration files, " % len( shed_tool_conf_select_field.options )
                select_help += "so select the file whose <b>tool_path</b> setting you want used for installing repositories."
        %>
        <div class="form-row">
            ${shed_tool_conf_select_field.get_html()}
            <div class="toolParamHelp" style="clear: both;">
                ${select_help}
            </div>
        </div>
        <div style="clear: both"></div>
        </div>
    </div>
    %endif
    <div class="toolForm">
        <div class="toolFormTitle">Tool panel section:</div>
        <div class="toolFormBody">
            <a class="toolformswitcher" id="select_existing">Select existing</a>
            <a class="toolformswitcher" id="create_new">Create new</a>
            <div class="form-row" id="select_tps">
                ${tool_panel_section_select_field.get_html()}
                <div class="toolParamHelp" style="clear: both;">
                    Select a new tool panel section to contain the installed tools (optional).
                </div>
            </div>
            <div class="form-row" id="new_tps">
                <input id="new_tool_panel_section" name="new_tool_panel_section" type="textfield" value="" size="40"/>
                <div class="toolParamHelp" style="clear: both;">
                    Add a new tool panel section to contain the installed tools (optional).
                </div>
            </div>
        </div>
    </div>
    <div class="toolForm" id="dependencies">
        <div class="toolFormTitle">Dependencies of this repository</div>
        <div class="toolFormBody">
            <table class="tables container-table" id="repository_dependencies" border="0" cellpadding="2" cellspacing="2" width="100%">
                <tbody id="repository_deps">
                    <tr id="folder-529fd61ab1c6cc36" class="folderRow libraryOrFolderRow expanded" bgcolor="#D8D8D8">
                        <td style="padding-left: 0px;">
                            <label for="install_repository_dependencies">Install repository dependencies</label>
                            <input type="checkbox" checked id="install_repository_dependencies" /><br />
                            <span class="expandLink folder-529fd61ab1c6cc36-click">
                                <div style="float: left; margin-left: 2px;" class="expandLink folder-529fd61ab1c6cc36-click">
                                    <a class="folder-529fd61ab1c6cc36-click" href="javascript:void(0);">
                                        Repository dependencies<i> - installation of these additional repositories is required</i>
                                    </a>
                                </div>
                            </span>
                        </td>
                    </tr>
                </tbody>
            </table>
            <table class="tables container-table" id="tool_dependencies" border="0" cellpadding="2" cellspacing="2" width="100%">
                <tbody id="tool_deps">
                    <tr id="folder-2234cb1fd1df4331" class="folderRow libraryOrFolderRow expanded" bgcolor="#D8D8D8">
                        <td colspan="4" style="padding-left: 0px;">
                            <label for="install_tool_dependencies">Install tool dependencies</label>
                            <input type="checkbox" checked id="install_tool_dependencies" /><br />
                            <span class="expandLink folder-2234cb1fd1df4331-click">
                                <div style="float: left; margin-left: 2px;" class="expandLink folder-2234cb1fd1df4331-click">
                                    <a class="folder-2234cb1fd1df4331-click" href="javascript:void(0);">
                                        Tool dependencies<i> - repository tools require handling of these dependencies</i>
                                    </a>
                                </div>
                            </span>
                        </td>
                    </tr>
                    <tr style="display: table-row;" class="datasetRow" parent="0" id="libraryItem-rtd-adb5f5c93f827949">
                        <th style="padding-left: 40px;">Name</th>
                        <th>Version</th>
                        <th>Type</th>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <div class="toolForm">
        <div class="toolFormTitle">Contents of this repository</div>
        <div class="toolFormBody">
            <table class="tables container-table" id="valid_tools" border="0" cellpadding="2" cellspacing="2" width="100%">
                <tbody id="tools_in_repo">
                    <tr id="folder-ed01147b4aa1e8de" class="folderRow libraryOrFolderRow expanded" bgcolor="#D8D8D8">
                        <td colspan="3" style="padding-left: 0px;">
                            <span class="expandLink folder-ed01147b4aa1e8de-click">
                                <div style="float: left; margin-left: 2px;" class="expandLink folder-ed01147b4aa1e8de-click">
                                    <a class="folder-ed01147b4aa1e8de-click" href="javascript:void(0);">
                                        Valid tools<i> - click the name to preview the tool and use the pop-up menu to inspect all metadata</i>
                                    </a>
                                </div>
                            </span>
                        </td>
                    </tr>
                    <tr style="display: table-row;" class="datasetRow" parent="0" id="libraryItem-rt-f9cad7b01a472135">
                        <th style="padding-left: 40px;">Name</th>
                        <th>Description</th>
                        <th>Version</th>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <input type="button" id="install_repository" name="install_repository" value="Install" />
</form>
