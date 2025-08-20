const login = @import("api/auth/login.zig");
const register = @import("api/auth/register.zig");
const refresh = @import("api/auth/refresh.zig");

const createProject = @import("api/project/create.zig");
const createProjectFn = createProject.create;
const findProject = @import("api/project/find.zig").find;
const getAllproject = @import("api/project/getAll.zig").getAll;
const deleteProject = @import("api/project/delete.zig").delete;
const updateProject = @import("api/project/update.zig").update;

const getAllSponsors = @import("api/sponsor/get.zig").getAll;
const deleteSponsor = @import("api/sponsor/delete.zig").delete;
const updateSponsor = @import("api/sponsor/update.zig").update;
const createSponsor = @import("api/sponsor/create.zig").create;

const getAllForms = @import("api/contact_form/get.zig").getAll;
const deleteForm = @import("api/contact_form/delete.zig").delete;
const updateForm = @import("api/contact_form/update.zig").updateConfirm;
const createForm = @import("api/contact_form/create.zig").create;

pub const InsertProjectError = createProject.Error;
pub const LoginError = login.Error;

pub const UnProtected = struct {
    pub const @"GET /ping" = @import("api/ping.zig").ping;
    pub const @"POST /login" = login.login;
    pub const @"POST /refresh" = refresh.refresh;
    pub const @"GET /projects" = getAllproject;
    pub const @"GET /sponsors" = getAllSponsors;

    pub const @"POST /contact-forms" = createForm;
};

pub const Protected = struct {
    pub const @"POST /register" = register.register;
    pub const @"GET /verify" = @import("api/auth/verify.zig").verify;

    pub const @"POST /projects" = createProjectFn;
    pub const @"DELETE /projects/:id" = deleteProject;
    pub const @"PUT /projects/:id" = updateProject;
    pub const @"GET /projects/:id" = findProject;

    pub const @"POST /sponsors" = createSponsor;
    pub const @"DELETE /sponsors/:id" = deleteSponsor;
    pub const @"PUT /sponsors/:id" = updateSponsor;

    pub const @"GET /contact-forms" = getAllForms;
    pub const @"DELETE /contact-forms/:id" = deleteForm;
    pub const @"PUT /contact-forms/:id" = updateForm;
};
