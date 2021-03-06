function FilterComponent(classification, filterPanelName) {
    this._basePath = classification;
    this._filterPanelControlName = filterPanelName !== undefined ? filterPanelName : "filter-panel";
    this._filterHelper = [];
    this._filterButtonIdentity = "." + this._basePath + " ." + this._filterPanelControlName + " .filter-toggle";
    this._filterPanelIdentity = "." + this._basePath + " ." + this._filterPanelControlName + " .filter-pane"
    this._filterTargetIdentity = "." + this._basePath + " ." + this._filterPanelControlName + " .filter-pane-target"
}
FilterComponent.prototype.init = function() {
    this.SynchroniseFilterToggleButton( this.onToggleButtonClick.bind(this));
    let sectionsDivs = $("." + this._basePath + " ." + this._filterPanelControlName).find('[data-section]');
    for ( let index = 0; index < sectionsDivs.length; index++) {
        this.AddSection(sectionsDivs[index].getAttribute('data-section'));
    }
};
FilterComponent.prototype.AddSection = function (sectionName) {
    this._filterHelper[sectionName] = new FilterSectionComponent(this._basePath, this._filterPanelControlName, sectionName);
    this._filterHelper.push(this._filterHelper[sectionName]);
};
FilterComponent.prototype.UpdateCounts = function () {
    let countTotal = 0;

    this._filterHelper.forEach(function (x) {
        countTotal += x.updateCount();
    });

    return countTotal;
};
FilterComponent.prototype.ConnectCheckboxes = function ( callback ) {
    let procHelper = this;

    this._filterHelper.forEach( function (filterHelper) {
        filterHelper.connectCheckboxes ( function (checkboxEvent) {
            procHelper.checkboxChangedHandler(checkboxEvent, callback );
        });
    }) ;
};
FilterComponent.prototype.onToggleButtonClick = function (filterEvent) {
    let filterPane = filterEvent.FilterPanel || null;
    let filterTarget = filterEvent.TargetPanel || null;

    if ( filterPane != null && filterTarget != null ) {
        let targetSection = filterTarget.jqueryObject;
        let filterButton = filterEvent.jqueryObject;
        let curText = filterButton.text();

        if ( filterEvent.IsHidden ) {
            filterPane.jqueryObject.attr('hidden', true);
            targetSection.removeClass('govuk-grid-column-two-thirds')
        } else {
            filterPane.jqueryObject.attr('hidden', false);
            targetSection.addClass('govuk-grid-column-two-thirds')
        }
        filterButton.text(filterButton.attr('alt-text'));
        filterButton.attr('alt-text', curText);
    }
};
FilterComponent.prototype.checkboxChangedHandler = function( checkboxEvent, clientCallback ) {
    let filterEvent = {
        FilterTarget : this.getFilterTarget(),
        FilterSection : checkboxEvent.type
    };
    this._filterHelper.forEach( function (x) {
        let propertyName = x._sectionName;
        let selectedCheckboxes = x.GetSelectedCheckboxes();
        filterEvent[propertyName+"_checkboxes"] = selectedCheckboxes;
    }) ;
    clientCallback(filterEvent);
};
FilterComponent.prototype.SynchroniseFilterToggleButton = function (TogglePanelCallback, PreventDefault) {
    let filterButton = null;
    let filterPanel = null;
    let filterTarget = null;

    filterButton = this.getFilterToggleButton();
    filterPanel = this.getFilterPanel();
    filterTarget = this.getFilterTarget();

    if (filterButton && filterButton.jqueryObject
        && filterPanel && filterPanel.jqueryObject
        && filterTarget && filterTarget.jqueryObject) {
        filterButton.jqueryObject.on('click', function (e) {
            if (PreventDefault == undefined  ||
                (PreventDefault !== undefined && !PreventDefault)) {
                e.preventDefault();
            }
            filterButton.IsHidden = filterPanel.jqueryObject.attr('hidden') ? false : true
            filterButton.FilterPanel = filterPanel;
            filterButton.TargetPanel = filterTarget;
            TogglePanelCallback(filterButton);
        });
    }
};
FilterComponent.prototype.getFilterTarget = function () {
    return {
        jqueryObject: $(this._filterTargetIdentity),
        class: this._basePath,
        helper: this,
        type : 'data-panel'
    };
};
FilterComponent.prototype.getFilterPanel = function () {
    return {
        jqueryObject: $(this._filterPanelIdentity),
        class: this._basePath,
        helper: this,
        type : 'filter-panel'
    };
};
FilterComponent.prototype.getFilterToggleButton = function () {
    return {
        jqueryObject: $(this._filterButtonIdentity),
        class: this._basePath,
        helper: this,
        type : 'filter-button'
    };
};

function FilterSectionComponent(baseClassName, filterPanelName, sectionName) {
    this._filterPanelControlName = filterPanelName;
    this._baseClass = baseClassName;
    this._sectionName = sectionName;

    this._sectionIdentifier = "." + this._baseClass + " ." + this._filterPanelControlName + " ." + this._sectionName + ".data-section";
    if ("" + sectionName != "" ) {
        this.sectionCheckboxes = $(this._sectionIdentifier + " input[name='facilities_management_" + this._baseClass + "[" + this._sectionName + "_codes][]']");
        this.sectionCounterTextField = $('#sproc-' + this._sectionName + '-count');
    }
}
FilterSectionComponent.prototype.GetSelectedCheckboxes = function (){
    let selectedCheckboxes = [];

    this.sectionCheckboxes.each( function ()  {
        if (this.checked) {
            selectedCheckboxes.push(this);
        }
    });
    
    return selectedCheckboxes;
};
FilterSectionComponent.prototype.connectCheckboxes = function (callback) {
    let filterHelper = this;
    this.sectionCheckboxes.on ( 'click', function (e) {
        filterHelper.updateCount();

        let jqueryObject = $(e.currentTarget);
        let checkboxEvent = {
            jqueryObject : jqueryObject,
            code : jqueryObject.val(),
            type : filterHelper._sectionName,
            selectedCheckboxes : filterHelper.GetSelectedCheckboxes()
        };
        
        callback(checkboxEvent) ;
    }) ;
} ;
FilterSectionComponent.prototype.updateCount = function () {
    let sectionCount = 0 ;
    this.sectionCheckboxes.each(function () {
        if (this.checked) {
            sectionCount++;
        }
    }) ;
    
    this.sectionCounterTextField.text(sectionCount + " selected");
    return this.sectionCheckboxes.length;
};
