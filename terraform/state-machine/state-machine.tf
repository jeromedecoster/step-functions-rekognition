variable project_name {}
# variable step_functions_name {}
# variable step_functions_role_arn {}
variable detect_faces_function_arn {}
variable add_to_collection_function_arn {}
variable no_face_detected_function_arn {}
# variable save_function_arn {}
variable thumbnail_function_arn {}

data template_file state_machine {
  template = file("${path.module}/state-machine.json")

  vars = {
    detect_faces_function_arn      = var.detect_faces_function_arn
    no_face_detected_function_arn  = var.no_face_detected_function_arn
    add_to_collection_function_arn = var.add_to_collection_function_arn
    #   save_function_arn              = var.save_function_arn
    thumbnail_function_arn = var.thumbnail_function_arn
  }
}

#
# state-machine assume role policy
#

data aws_iam_policy_document state_machine_assume_role_policy {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "states.amazonaws.com"
      ]
    }
  }
}

resource aws_iam_role state_machine_role {
  name               = "${var.project_name}-state-machine-role"
  assume_role_policy = data.aws_iam_policy_document.state_machine_assume_role_policy.json
}

resource aws_sfn_state_machine state_machine {
  definition = data.template_file.state_machine.rendered
  name       = "${var.project_name}-state-machine"
  role_arn   = aws_iam_role.state_machine_role.arn
}

#
# state-machine policy
#

data aws_iam_policy_document state_machine_policy {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = ["*"]
  }

  statement {
    actions   = ["states:StartExecution"]
    resources = ["*"]
  }

  statement {
    actions   = ["logs:*"]
    resources = ["*"]
  }
}

resource aws_iam_policy state_machine_policy {
  name   = "${var.project_name}-state-machine-policy"
  policy = data.aws_iam_policy_document.state_machine_policy.json
}

// TODO : remove aws_iam_role_policy_attachment
resource aws_iam_role_policy_attachment state_machine_role_attached_policy {
  role       = aws_iam_role.state_machine_role.name
  policy_arn = aws_iam_policy.state_machine_policy.arn
}


output state_machine_arn {
  value = aws_sfn_state_machine.state_machine.id
}